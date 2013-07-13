/*------------------------------------------------------------------------------

   MiniLight Flex : minimal global illumination renderer
   Copyright (c) 2007-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*/




package org.hxa7241.flex.minilight
{


import flash.errors.EOFError;

import org.hxa7241.flex.general.StringStreamIn;
import org.hxa7241.flex.general.RandomMwc;
import org.hxa7241.flex.graphics.Vector3f;


/**
 * A grouping of the objects in the environment.
 *
 * <p>Makes a sub-grouping of emitting objects.</p>
 *
 * <p>Constant.</p>
 *
 * @invariants
 * <ul>
 *    <li>triangles_m elements are Triangle</li>
 *    <li>triangles_m.length <= 2^20</li>
 *    <li>emitters_m elements are Triangle</li>
 *    <li>emitters_m.length  <= 2^20</li>
 *    <li>skyEmission_m      >= 0</li>
 *    <li>groundReflection_m >= 0</li>
 *    <li>all fields not null</li>
 * </ul>
 */
public class Scene
{
   public function Scene(
      modelFile   :StringStreamIn,
      eyePosition :Vector3f )
   {
      // read and condition default sky and ground values

      skyEmission_m = new Vector3f( modelFile );
      skyEmission_m = skyEmission_m.getClamped( Vector3f.ZERO, skyEmission_m );

      groundReflection_m = skyEmission_m.multiply( new Vector3f( modelFile
         ).getClamped( Vector3f.ZERO, Vector3f.ONE ) );

      // read objects
      try
      {
         for( var i :uint = 0;  i < MAX_TRIANGLES;  ++i )
         {
            triangles_m.push( new Triangle( modelFile ) );
         }
      }
      catch( e :EOFError )
      {
         // EOF is not really exceptional here, but the code is simpler.
         // (if a triangle is cut short by EOF, it won't be added to the array,
         // but the previous ones are ok)
      }

      // find emitting triangles
      emitters_m = triangles_m.filter( function( item :*, ... z ) :Boolean
         {
            // has non-zero emission and area
            return !item.emitivity.isZero() && (item.area > 0.0);
         } );

      // make index
      index_m = new SpatialIndex( eyePosition, triangles_m );
   }


/// queries --------------------------------------------------------------------
   /**
    * Find nearest intersection of ray with triangle.
    *
    * @param lastHit previous intersected object
    *
    * @return object with members:
    * <ul>
    *    <li>object   :Triangle  hit object or null</li>
    *    <li>position :Vector3fc hit position or null</li>
    * </ul>
    */
   public function getIntersection(
      rayOrigin    :Vector3f,
      rayDirection :Vector3f,
      lastHit      :Object ) :Object
   {
      const hit :Object = { object: null, position: null };
      index_m.getIntersection( rayOrigin, rayDirection, lastHit, hit );

      return hit;
   }


   /**
    * Monte-carlo sample point on monte-carlo selected emitting triangle.
    *
    * @return object with members:
    * <ul>
    *    <li>position :Vector3fc position or null</li>
    *    <li>id       :Triangle  object or null</li>
    * </ul>
    */
   public function getEmitter(
      random :RandomMwc ) :Object
   {
      // select emitter
      // not using lower bits, by treating the random as fixed-point i.f bits
      const emitter :Triangle = (emitters_m.length <= 0) ? null :
         emitters_m[ ((random.integer & ((1 << MAX_TRIANGLES_P) - 1)) *
         emitters_m.length) >>> MAX_TRIANGLES_P ];

      // get position on triangle
      return { position: (!emitter ? null : emitter.getSamplePoint( random )),
         id: emitter };
   }


   /**
    * Number of emitters in scene.
    */
   public function get emittersCount() :uint
   {
      return emitters_m.length;
   }


   /**
    * Default/'background' light of scene universe.
    *
    * @param backDirection direction from emitting point
    *
    * @return emitted radiance
    */
   public function getDefaultEmission(
      backDirection :Vector3f ) :Vector3f
   {
      // sky for downward ray, ground for upward ray
      return (backDirection.y < 0.0) ? skyEmission_m : groundReflection_m;
   }


/// commands -------------------------------------------------------------------


/// constants ------------------------------------------------------------------
   // 2^20 ~= a million
   private static const MAX_TRIANGLES_P :uint = 20;
   private static const MAX_TRIANGLES   :uint = 1 << MAX_TRIANGLES_P;


/// fields ---------------------------------------------------------------------
   private const triangles_m :Array = [];
   private var   emitters_m  :Array;
   private var   index_m     :SpatialIndex;

   private var   skyEmission_m      :Vector3f;
   private var   groundReflection_m :Vector3f;
}


}
