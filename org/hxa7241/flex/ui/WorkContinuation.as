/*------------------------------------------------------------------------------

   HXA7241 Flex library
   Copyright (c) 2007, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*/




package org.hxa7241.flex.ui
{


import flash.utils.getTimer;
import mx.core.Application;


/**
 * Framework for continued execution of long work in small slices.
 *
 * @invariants
 * <ul>
 *    <li>worker_m is not null</li>
 * </ul>
 */
public class WorkContinuation
{
   public function WorkContinuation(
      worker        :IWorkContinuation,
      chunkDuration :Number = 30.0 )
   {
      // check precondition
      if( !worker )
      {
         throw new TypeError( "worker is null" );
      }

      worker_m        = worker;
      chunkDuration_m = int( chunkDuration && (chunkDuration >= 0.0) ?
         (chunkDuration <= 1000.0 ? chunkDuration : 1000.0) : 0.0 );

      Application.application.callLater( this.work );
   }


/// queries --------------------------------------------------------------------
   public function get isWorkTodo() :Boolean
   {
      return worker_m.isWorkTodo;
   }


   public function get worker() :Object
   {
      return worker_m;
   }


/// commands -------------------------------------------------------------------
   public function suspend() :void
   {
      if( !isSuspended_m )
      {
         isSuspended_m = true;

         worker_m.suspend();
      }
   }


   public function resume() :void
   {
      if( isSuspended_m )
      {
         isSuspended_m = false;

         worker_m.resume();

         Application.application.callLater( work );
      }
   }


   public function reset() :void
   {
      isSuspended_m = false;

      worker_m.reset();
   }


/// implementation -------------------------------------------------------------
   protected function work() :void
   {
      // check work to do, and not suspended
      if( isWorkTodo && !isSuspended_m )
      {
         worker_m.preChunk();

         // prepare timing for this chunk
         const startTime :int = getTimer();

         // do some work for a while
         do
         {
            // delegate to sub-object
            worker_m.doSlice();
            const isTimeLeft :Boolean = (getTimer() - startTime) <
               chunkDuration_m;
         // if work completed or duration max reached, exit loop
         } while( isWorkTodo && isTimeLeft );

         // request more application time if needed
         if( isWorkTodo )
         {
            Application.application.callLater( work );
         }

         worker_m.postChunk();
      }
   }


/// fields ---------------------------------------------------------------------
   private var worker_m        :IWorkContinuation;
   private var chunkDuration_m :int;

   private var isSuspended_m :Boolean;
}


}
