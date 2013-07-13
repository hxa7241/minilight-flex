/*------------------------------------------------------------------------------

   MiniLight Flex : minimal global illumination renderer
   Copyright (c) 2007-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*/




package org.hxa7241.flex.minilight
{


import org.hxa7241.flex.general.RandomMwc;
import org.hxa7241.flex.graphics.Vector3f;


/**
 * Surface point at a ray-object intersection.
 *
 * <p>All direction parameters are away from surface.</p>
 *
 * <p>Constant.</p>
 *
 * @invariants
 * <ul>
 *    <li>all fields not null</li>
 * </ul>
 */
public class SurfacePoint
{
   public function SurfacePoint(
      triangle :Triangle,
      position :Vector3f )
   {
      triangle_m = triangle;
      position_m = position;
   }


/// queries --------------------------------------------------------------------
   /**
    * Emission from surface element to point.
    *
    * @param toPosition point being illuminated
    * @param outDirection direction (unitized) from emitting point
    * @param isSolidAngle is solid angle used
    *
    * @return emitted radiance
    */
   public function getEmission(
      toPosition   :Vector3f,
      outDirection :Vector3f,
      isSolidAngle :Boolean ) :Vector3f
   {
      const ray       :Vector3f = toPosition.minus( position_m );
      const distance2 :Number   = ray.dot( ray );
      const cosArea   :Number   = outDirection.dot( triangle_m.normal ) *
         triangle_m.area;

      // clamp-out infinity
      const solidAngle :Number = isSolidAngle ?
         cosArea / (distance2 >= 1e-6 ? distance2 : 1e-6) : 1.0;

      // emit from front face of surface only
      return cosArea > 0.0 ?
         triangle_m.emitivity.multiply(solidAngle) : Vector3f.ZERO;
   }


   /**
    * Light reflection from ray to ray by surface.
    *
    * @param inDirection negative of inward ray direction
    * @param inRadiance inward radiance
    * @param outDirection outward ray (towards eye) direction
    *
    * @return reflected radiance
    */
   public function getReflection(
      inDirection  :Vector3f,
      inRadiance   :Vector3f,
      outDirection :Vector3f ) :Vector3f
   {
      const inDot  :Number = inDirection.dot(  triangle_m.normal );
      const outDot :Number = outDirection.dot( triangle_m.normal );

      // directions must be on same side of surface
      return uint(inDot < 0.0) ^ uint(outDot < 0.0) ? Vector3f.ZERO :
         // ideal diffuse BRDF:
         // radiance scaled by cosine, 1/pi, and reflectivity
         inRadiance.multiply( triangle_m.reflectivity ).multiply(
            Math.abs(inDot) / Math.PI );
   }


   /**
    * Monte-carlo direction of reflection from surface.
    *
    * @param inDirection eyeward ray direction
    *
    * @return null or Object with members:
    * <ul>
    *    <li>direction :Vector3f sceneward ray direction unitized</li>
    *    <li>color     :Vector3f color of interaction point</li>
    * </ul>
    */
   public function getNextDirection(
      random       :RandomMwc,
      inDirection  :Vector3f ) :Object
   {
      const reflectivityMean :Number =
         triangle_m.reflectivity.dot( Vector3f.ONE ) / 3.0;

      // russian-roulette for reflectance magnitude
      if( random.float < reflectivityMean )
      {
         const color :Vector3f = triangle_m.reflectivity.divide(
            reflectivityMean );

         // cosine-weighted importance sample hemisphere

         const _2pr1 :Number = Math.PI * 2.0 * random.float;
         const sr2   :Number = Math.sqrt( random.float );

         // make coord frame coefficients (z in normal direction)
         const x :Number = Math.cos( _2pr1 ) * sr2;
         const y :Number = Math.sin( _2pr1 ) * sr2;
         const z :Number = Math.sqrt( 1.0 - (sr2 * sr2) );

         // make coord frame
         const tangent :Vector3f = triangle_m.tangent;
         var   normal  :Vector3f = triangle_m.normal;
         normal = normal.dot( inDirection ) >= 0.0 ? normal : normal.negative();

         // make vector from frame times coefficients
         const outDirection :Vector3f = tangent.multiply(x).plus(
            normal.cross( tangent ).multiply(y) ).plus( normal.multiply(z) );

         const result :Object = { direction: outDirection, color: color };
      }

      return result ? result : null;
   }


   public function get hitId() :Object
   {
      return triangle_m;
   }


   public function get position() :Vector3f
   {
      return position_m;
   }


/// commands -------------------------------------------------------------------


/// fields ---------------------------------------------------------------------
   private var triangle_m :Triangle;
   private var position_m :Vector3f;
}


}
