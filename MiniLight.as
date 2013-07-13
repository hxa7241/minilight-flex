/*------------------------------------------------------------------------------

   MiniLight Flex : minimal global illumination renderer
   Copyright (c) 2007-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*/




package
{


import flash.system.System;
import mx.core.Application;
import mx.controls.Alert;

import org.hxa7241.flex.ui.WorkContinuation;


/**
 * Main UI logic.
 *
 * <p>Has two main states: loading and rendering (each being an asynchronous
 * activity). When loading ends it initiates rendering. When rendering ends it
 * remains existing but quiescent. (There is also the null state, with nothing
 * happening.)</p>
 *
 * @invariants
 * <ul>
 *    <li>one or both of loadingStop_m and rendering_m are null</li>
 * </ul>
 */
public class MiniLight
{
   public function MiniLight()
   {
   }


/// queries --------------------------------------------------------------------


/// commands -------------------------------------------------------------------
   public function start() :void
   {
      invertButtons();

      rendering_m = null;

      try
      {
         loadingStop_m = loadFile( app_m.modelFileUrl.text, showProgress,
            finishLoading, handleException );
      }
      catch( e :Error )
      {
         handleException( e.name + ": " + e.message );
      }
   }


   public function stop() :void
   {
      invertButtons();

      if( null != loadingStop_m )
      {
         loadingStop_m();
      }

      if( rendering_m )
      {
         rendering_m.suspend();
      }
   }


   public function copy() :void
   {
      if( rendering_m )
      {
         System.setClipboard( Rendering(rendering_m.worker).imageString );
      }
   }


/// implementation -------------------------------------------------------------
   private function showProgress(
      howFar :uint,
      total  :uint,
      label  :String ) :void
   {
      app_m.progress.setProgress( howFar, total );
      app_m.progress.label = label;
   }


   private function finishLoading(
      modelString :String ) :void
   {
      loadingStop_m = null;

      // check format identifier (must be first thing in model string)
      if( -1 != modelString.search( new RegExp( "^" + MODEL_FORMAT_ID ) ) )
      {
         // chop off format identifier (before first blank)
         modelString = modelString.substr( modelString.search(/\s/) );

         showProgress( 0, 0, "preparing..." );

         // defer to next frame to allow progress message to be shown
         app_m.callLater( function() :void
            {
               try
               {
                  // 80 for frame rate of 10, 30 for frame rate of 24
                  // (set frame rate with <mx:Application frameRate="16">)
                  const chunkDuration :Number = app_m.stage.frameRate ?
                     (1000.0 / app_m.stage.frameRate) * 0.8 : 30;

                  // start rendering
                  rendering_m = new WorkContinuation( new Rendering(
                     modelString, app_m.image, showProgress, finishRendering,
                     handleException ), chunkDuration );
               }
               catch( e :Error )
               {
                  handleException( e.name + ": " + e.message );
               }
            } );
      }
      else
      {
         handleException( "Invalid model file: there is something wrong with " +
            "its content, or it just is not a model file." );
      }
   }


   private function finishRendering() :void
   {
      resetButtons();
   }


   private function handleException(
      message :String ) :void
   {
      resetButtons();

      loadingStop_m = null;
      rendering_m   = null;

      Alert.show( message, "exception" );
   }


   private function invertButtons() :void
   {
      app_m.startButton.enabled = !app_m.startButton.enabled;
      app_m.stopButton.enabled  = !app_m.stopButton.enabled;
   }


   private function resetButtons() :void
   {
      app_m.startButton.enabled = true;
      app_m.stopButton.enabled  = false
   }


/// constants ------------------------------------------------------------------
   private static const MODEL_FORMAT_ID :String = "#MiniLight";


/// fields ---------------------------------------------------------------------
   private const app_m :minilight = minilight(Application.application);

   private var loadingStop_m :Function;
   private var rendering_m   :WorkContinuation;
}


}








/// internals //////////////////////////////////////////////////////////////////

import flash.events.*;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.display.BitmapData;
//import flash.utils.getTimer;

import org.hxa7241.flex.ui.IWorkContinuation;
import org.hxa7241.flex.ui.Pixmap;

import org.hxa7241.flex.general.StringStreamIn;
import org.hxa7241.flex.general.RandomMwc;
import org.hxa7241.flex.minilight.Image;
import org.hxa7241.flex.minilight.Camera;
import org.hxa7241.flex.minilight.Scene;




/**
 * Spawn a file-loading activity.
 *
 * @param progressHandler  :function( howFar :uint, total :uint, label :String )
 *    :void
 * @param completedHandler :function( modelFileString :String ) :void
 * @param exceptionHandler :function( message :String ) :void
 *
 * @return function():void call to abort
 */
function loadFile(
   url              :String,
   progressHandler  :Function,
   completedHandler :Function,
   exceptionHandler :Function ) :Function
{
   progressHandler( 0, 0, "file loading..." )

   const loader :URLLoader = new URLLoader();

   // register handlers
   loader.addEventListener( ProgressEvent.PROGRESS,
      function( event :ProgressEvent ) :void
      { progressHandler( event.bytesLoaded, event.bytesTotal,
      "file loaded: %3 %%" ); } );
   loader.addEventListener( Event.COMPLETE,
      function( event :Event ) :void
      { completedHandler( event.target.data ); } );
   loader.addEventListener( IOErrorEvent.IO_ERROR,
      function( event :ErrorEvent ) :void
      { exceptionHandler( event.type + ": maybe the model URL is incorrect, " +
         "or the file isn't there." ); } );
   loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR,
      function( event :ErrorEvent ) :void
      { exceptionHandler( event.type + ": maybe special permissions are " +
         "needed to reach that location." ); } );

   // start loading
   loader.load( new URLRequest( encodeURI( url ) ) );

   // return a (fail-inert) means of aborting
   return function() :void { try{ loader.close(); } catch( e :Error ){} };
}




/**
 * Rendering root procedure, arranged for execution in many small slices.
 *
 * <p>Essentially a loop made into a class: loop counters and iteration state
 * are in fields, loop body in a method (doSlice).</p>
 *
 * <p>There are two phases: preparation and then tracing. Preparation
 * initializes the rendering constituents. Tracing traces a single ray each
 * slice.</p>
 *
 * @see IWorkContinuation, WorkContinuation
 *
 * @todo
 * <p>Rewrite SpatialIndex so Scene initialization, and so preparation can be
 * split into multiple slices. At present, models of a few hundred or more
 * triangles take a few seconds to construct -- only just acceptable.</p>
 */
class Rendering implements IWorkContinuation
{
   public function Rendering(
      modelFileString  :String,
      pixmap           :Pixmap,
      progressHandler  :Function,
      completedHandler :Function,
      exceptionHandler :Function )
   {
      progressHandler_m  = progressHandler;
      completedHandler_m = completedHandler;
      exceptionHandler_m = exceptionHandler;
      modelFile_m        = new StringStreamIn( modelFileString );

      //startTime_m = getTimer();

      // read frame iterations
      iterations_m = uint( modelFile_m.number() );

      // set bitmap size (nb: must read in this order)
      const width  :uint = uint(modelFile_m.number());
      const height :uint = uint(modelFile_m.number());
      pixmap.setBitmapSize( width, height );

      pixels_m = pixmap.bitmapData;
      pixels_m.noise( 0, 0, 0 );
   }


/// queries --------------------------------------------------------------------
   public function get imageString() :String
   {
      return image_m ? image_m.formatted : "";
   }


   // interface implementation
   public function get isWorkTodo() :Boolean
   {
      return frameNo_m <= iterations_m;
   }


/// commands -------------------------------------------------------------------
   // interface implementations

   public function doSlice() :void
   {
      try
      {
         // preparation phase (deferred construction)
         if( 0 == frameNo_m )
         {
            // create top-level rendering objects with model file
            image_m  = new Image( pixels_m );
            camera_m = new Camera( modelFile_m );
            scene_m  = new Scene( modelFile_m, camera_m.eyePoint );

            progressHandler_m( 0, iterations_m, "iteration: %1 (of %2)" );

            ++frameNo_m;
            reset();
         }
         // progressive render phase
         else
         {
            // trace a pixel, and advance position
            camera_m.getPixel( scene_m, x_m, y_m, random_m, image_m );

            x_m = x_m < (image_m.width - 1) ? x_m + 1 : 0;
            y_m = x_m > 0 ? y_m : y_m + 1;

            // when whole frame done
            if( image_m.height == y_m )
            {
               y_m = 0;

               image_m.updateMapping();

               ++frameNo_m;
            }

            // continue or finish all
            if( !isWorkTodo )
            {
               finish();
            }
         }
      }
      catch( e :Error )
      {
         // stop further work
         frameNo_m = uint.MAX_VALUE;

         exceptionHandler_m( e.name + ": " + e.message );
      }
   }


   public function preChunk() :void
   {
      pixels_m.lock();
   }


   public function postChunk() :void
   {
      pixels_m.unlock();
      showProgress();
   }


   public function suspend() :void
   {
      if( (frameNo_m > 0) && isWorkTodo )
      {
         image_m.updateMapping();
      }
   }


   public function resume() :void
   {
   }


   public function reset() :void
   {
      random_m  = new RandomMwc();//uint(new Date().time)
      x_m       = 0;
      y_m       = 0;
      frameNo_m = (0 == frameNo_m) ? 0 : 1;
   }


/// implementation -------------------------------------------------------------
   private function showProgress() :void
   {
      //const time :Number = Math.floor((getTimer() - startTime_m) / 1000.0);

      const imageLength   :uint = image_m.width * image_m.height;
      const totalPixels   :uint = iterations_m * imageLength;
      const framePixel    :uint = x_m + (y_m * image_m.width);
      const pixelNo       :uint = framePixel + ((frameNo_m - 1) * imageLength);
      const frameFraction :Number = frameNo_m - 1 + (framePixel / imageLength);

      if( frameNo_m < uint.MAX_VALUE )
      {
         progressHandler_m( pixelNo, totalPixels,
            "iteration: " + frameFraction.toFixed(2) + " (of " + iterations_m +
            ")" );//+ "  " + time + " sec" );
      }
      else
      {
         progressHandler_m( pixelNo, totalPixels, "stopped by exception" );
      }
   }


   private function finish() :void
   {
      completedHandler_m();
   }


/// fields ---------------------------------------------------------------------
   private var progressHandler_m  :Function;
   private var completedHandler_m :Function;
   private var exceptionHandler_m :Function;
   private var pixels_m           :BitmapData;
   private var modelFile_m        :StringStreamIn;

   private var iterations_m :uint;
   private var image_m      :Image;
   private var camera_m     :Camera;
   private var scene_m      :Scene;

   private var random_m  :RandomMwc;
   private var x_m       :uint;
   private var y_m       :uint;
   private var frameNo_m :uint;

   //private var startTime_m :int;
}
