/*------------------------------------------------------------------------------

   MiniLight Flex : minimal global illumination renderer
   Copyright (c) 2007-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*/




package org.hxa7241.flex.minilight
{


import org.hxa7241.flex.graphics.Vector3f;


/**
 * A minimal spatial index for ray tracing.
 *
 * <p>Suitable for a scale of 1 metre == 1 numerical unit, and has a resolution
 * of 1 millimetre. (Implementation uses fixed tolerances)</p>
 *
 * <p>Constant.</p>
 *
 * @implementation
 * <p>A degenerate State pattern: typed by isBranch_m field to be either a
 * branch or leaf cell.</p>
 *
 * <p>Octree: axis-aligned, cubical. Subcells are numbered thusly:</p>
 * <pre>      110---111
 *            /|    /|
 *         010---011 |
 *    y z   | 100-|-101
 *    |/    |/    | /
 *    .-x  000---001      </pre>
 *
 * <p>Each cell stores its bound: fatter data, but simpler code.</p>
 *
 * <p>Calculations for building and tracing are absolute rather than incremental
 * -- so quite numerically solid. Uses tolerances in: bounding triangles (in
 * Triangle.getBound), and checking intersection is inside cell (both effective
 * for axis-aligned items). Also, depth is constrained to an absolute subcell
 * size (easy way to handle overlapping items).</p>
 *
 * <p>Some loops have been unrolled, and array comprehensions replaced with
 * loops, where speed increases were significant.</p>
 *
 * @invariants
 * <ul>
 *    <li>bound_m elements are Number</li>
 *    <li>bound_m.length is 6</li>
 *    <li>bound_m[0-2] <= bound_m[3-5]</li>
 *    <li>bound_m encompasses the cell's contents</li>
 * </ul>
 * if isBranch_m
 * <ul>
 *    <li>vector_m.length is 8</li>
 *    <li>vector_m elements are null or SpatialIndex</li>
 * </ul>
 * else
 * <ul>
 *    <li>vector_m elements are (non-null) Triangle</li>
 * </ul>
 */
public class SpatialIndex
{
   /**
    * @parameters either:
    * <ul>
    *    <li>arg   Vector3f (eyePosition)</li>
    *    <li>items Array of Triangle</li>
    * </ul>
    * or:
    * <ul>
    *    <li>arg   Array of 6 Number (bound)</li>
    *    <li>items Array of Object of {bound, Triangle}</li>
    *    <li>level uint</li>
    * </ul>
    */
   public function SpatialIndex(
      arg   :*,
      items :Array,
      level :uint = 0 )
   {
      // set the overall bound, if root call of recursion
      if( arg is Vector3f )
      {
         // make all item bounds
         items = items.map( function( item :*, ... z ) :Object
            { return { bound_: item.bound, item_: item }; } );

         // accommodate all items, and eye position (makes tracing algorithm
         // simpler)
         bound_m = [ arg.x, arg.y, arg.z, arg.x, arg.y, arg.z ];
         for each ( var item :Object in items )
         {
            // accommodate item
            for( var j :uint = 6;  j-- > 0; )
            {
               bound_m[j] = uint(bound_m[j] > item.bound_[j]) ^ uint(j > 2) ?
                  item.bound_[j] : bound_m[j];
            }
         }

         // make cubical
         for( var maxSize :Number = 0.0, i :uint = 3;  i-- > 0; )
         {
            const size :Number = bound_m[i + 3] - bound_m[i];
            maxSize = size > maxSize ? size : maxSize;
         }
         for( var k :uint = 3;  k-- > 0; )
         {
            var s :Number = bound_m[k] + maxSize;
            if( bound_m[k + 3] < s ) bound_m[k + 3] = s;
         }
      }
      else
      {
         bound_m = arg;
      }

      // is branch if items overflow leaf and tree not too deep
      isBranch_m = (items.length > MAX_ITEMS) && (level < (MAX_LEVELS - 1));

      // be branch: make sub-cells, and recurse construction
      if( isBranch_m )
      {
         var q1 :uint = 0;

         // make subcells
         vector_m = new Array( 8 );
         for( var sc :uint = 0;  sc < 8;  ++sc )
         {
            // make subcell bound
            const subBound :Array = [
               sc & 1        ? (bound_m[0] + bound_m[3]) * 0.5 : bound_m[0],
               (sc >> 1) & 1 ? (bound_m[1] + bound_m[4]) * 0.5 : bound_m[1],
               (sc >> 2) & 1 ? (bound_m[2] + bound_m[5]) * 0.5 : bound_m[2],
               sc & 1        ? bound_m[3] : (bound_m[0] + bound_m[3]) * 0.5,
               (sc >> 1) & 1 ? bound_m[4] : (bound_m[1] + bound_m[4]) * 0.5,
               (sc >> 2) & 1 ? bound_m[5] : (bound_m[2] + bound_m[5]) * 0.5 ];

            // collect items that overlap subcell
            // (Array.filter is significantly slower)
            const subItems :Array = new Array();
            for each ( var it :Object in items )
            {
               if( (it.bound_[3] >= subBound[0]) && (it.bound_[0] <
                  subBound[3]) && (it.bound_[4] >= subBound[1]) &&
                  (it.bound_[1] < subBound[4]) && (it.bound_[5] >=
                  subBound[2]) && (it.bound_[2] < subBound[5]) )
               {
                  subItems.push( it );
               }
            }

            // curtail degenerate subdivision by adjusting next level
            // (degenerate if two or more subcells copy entire contents of
            // parent, or if subdivision reaches below mm size)
            // (having a model including the sun requires one subcell copying
            // entire contents of parent to be allowed)
            q1 += ((subItems.length == items.length) ? 1 : 0);
            const q2:Boolean = (subBound[3] - subBound[0]) <
               (Triangle.TOLERANCE * 4.0);

            // recurse
            vector_m[sc] = (0 != subItems.length) ? new SpatialIndex( subBound,
               subItems, ((q1 > 1) || q2 ? MAX_LEVELS : level + 1) ) : null;
         }
      }
      // be leaf: store items, and end recursion
      // (trim reserve capacity ?)
      else
      {
         // (Array.map is significantly slower)
         vector_m = new Array( items.length );
         for( var v :uint = items.length;  v-- > 0; )
         {
            vector_m[v] = items[v].item_;
         }
      }
   }


/// queries --------------------------------------------------------------------
   /**
    * Find nearest intersection of ray with item.
    *
    * @param lastHit previous intersected object
    * @param hit with members:
    * <ul>
    *    <li>object   :Triangle  hit object or null</li>
    *    <li>position :Vector3fc hit position or null</li>
    * </ul>
    * @param start traversal position
    */
   public function getIntersection(
      rayOrigin    :Vector3f,
      rayDirection :Vector3f,
      lastHit      :Object,
      hit          :Object,
      start        :Vector3f = null ) :void
   {
      // is branch: step through subcells and recurse
      if( isBranch_m )
      {
         start = start ? start : rayOrigin;

         // find which subcell holds ray origin (ray origin is inside cell)
         for( var subCell :uint = 0, i :uint = 3;  i-- > 0; )
         {
            // compare dimension with center
            subCell |= uint(start.get(i) >= ((bound_m[i] + bound_m[i + 3]) *
               0.5)) << i;
         }

         // step through intersected subcells
         for( var cellPosition :Vector3f = start;  true; )
         {
            if( vector_m[subCell] )
            {
               // intersect subcell
               vector_m[subCell].getIntersection( rayOrigin, rayDirection,
                  lastHit, hit, cellPosition );
               // exit if item hit
               if( hit.object )
               {
                  break;
               }
            }

            // find next subcell ray moves to
            // (by finding which face of the corner ahead is crossed first)
            var step :Number = Number.MAX_VALUE;
            var axis :uint   = 0;
            for( var k :uint = 3;  k-- > 0; )
            {
               const high :uint   = (subCell >> k) & 1;
               const face :Number = uint(rayDirection.get(k) < 0.0) ^ high ?
                  bound_m[k + (high * 3)] : (bound_m[k] + bound_m[k + 3]) * 0.5;
               const distance :Number = (face - rayOrigin.get(k)) /
                  rayDirection.get(k);

               if( distance <= step )
               {
                  step = distance;  axis = k;
               }
            }

            // leaving branch if: subcell is low and direction is negative,
            // or subcell is high and direction is positive
            if( ((subCell >> axis) & 1) ^ uint(rayDirection.get(axis) < 0.0) )
            {
               break;
            }

            // move to (outer face of) next subcell
            cellPosition = rayOrigin.plus( rayDirection.multiply( step ) );
            subCell      = subCell ^ (1 << axis);
         }
      }
      // is leaf: exhaustively intersect contained items
      else
      {
         hit.object = null;
         var nearestDistance :Number = Number.MAX_VALUE;

         // step through items
         for each( var item :Triangle in vector_m )
         {
            // avoid false intersection with surface just come from
            if( item != Triangle(lastHit) )
            {
               // intersect ray with item, and inspect if nearest so far
               const hitDistance :Number = item.getIntersection( rayOrigin,
                  rayDirection );
               if( hitDistance < nearestDistance )
               {
                  // check intersection is inside cell bound (with tolerance)
                  const hitPosition :Vector3f = rayOrigin.plus(
                     rayDirection.multiply( hitDistance ) );
                  if( (bound_m[0] - hitPosition.x <= Triangle.TOLERANCE) &&
                     (hitPosition.x - bound_m[3] <= Triangle.TOLERANCE) &&
                     (bound_m[1] - hitPosition.y <= Triangle.TOLERANCE) &&
                     (hitPosition.y - bound_m[4] <= Triangle.TOLERANCE) &&
                     (bound_m[2] - hitPosition.z <= Triangle.TOLERANCE) &&
                     (hitPosition.z - bound_m[5] <= Triangle.TOLERANCE) )
                  {
                     hit.object      = item;
                     hit.position    = hitPosition;
                     nearestDistance = hitDistance
                  }
               }
            }
         }
      }
   }


/// commands -------------------------------------------------------------------


/// constants ------------------------------------------------------------------
   // accommodates scene including sun and earth, down to cm cells
   // (use 47 for mm)
   public static const MAX_LEVELS :uint = 44;
   public static const MAX_ITEMS  :uint =  8;


/// fields ---------------------------------------------------------------------
   private var isBranch_m :Boolean;
   private var bound_m    :Array;
   private var vector_m   :Array;
}


}
