/*------------------------------------------------------------------------------

   HXA7241 Flex library
   Copyright (c) 2007, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*/




package org.hxa7241.flex.ui
{


/**
 * Framework for continued execution of long work in small slices.
 *
 * <p>Implement and give instance to WorkContinuation.</p>
 *
 * <p>The main sequence each frame is:</p>
 * <pre>
 *    preChunk()
 *    loop for about frame duration
 *       doSlice()
 *    postChunk()
 * </pre>
 */
public interface IWorkContinuation
{
/// queries --------------------------------------------------------------------
   /**
    * @return true if there is still work to be done
    */
   function get isWorkTodo() :Boolean;


/// commands -------------------------------------------------------------------
   /**
    * Do the next piece of work -- taking less than 20 milliseconds.
    *
    * <p>(Implementation like a loop with counters etc. in class fields.)</p>
    */
   function doSlice() :void;

   /**
    * Do pre-work-chunk stuff.
    */
   function preChunk() :void;

   /**
    * Do post-work-chunk stuff.
    */
   function postChunk() :void;

   /**
    * Suspend (indefinitely) work.
    */
   function suspend() :void;

   /**
    * Resume work after being suspended.
    */
   function resume() :void;

   /**
    * Reset state to begin work -- same as immediately after construction.
    */
   function reset() :void;
}


}
