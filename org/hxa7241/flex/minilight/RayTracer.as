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
 * Ray tracer for general light transport.
 *
 * <p>Traces a path with emitter sampling each step: A single chain of ray-steps
 * advances from the eye into the scene with one sampling of emitters at each
 * node.</p>
 *
 * <p>Constant.</p>
 *
 * @invariants
 * <ul>
 *    <li>scene_m is non-null</li>
 * </ul>
 */
public class RayTracer
{
   public function RayTracer(
      scene :Scene )
   {
      scene_m = scene;
   }


/// queries --------------------------------------------------------------------
   /**
    * Returned radiance from a trace.
    *
    * @param rayOrigin ray start point
    * @param rayDirection ray direction unitized
    * @param lastHit a ref to the previous intersected object in the scene
    *
    * @return radiance back along ray direction
    */
   public function getRadiance(
      rayOrigin    :Vector3f,
      rayDirection :Vector3f,
      random       :RandomMwc,
      lastHit      :Object = null ) :Vector3f
   {
      // intersect ray with scene
      const hit :Object = scene_m.getIntersection( rayOrigin, rayDirection,
         lastHit );

      if( hit.object )
      {
         // make surface point of intersection
         const surfacePoint :SurfacePoint = new SurfacePoint(
            hit.object, hit.position );

         // local emission only for first-hit
         var radiance :Vector3f = !lastHit ? surfacePoint.getEmission(
            rayOrigin, rayDirection.negative(), false ) : Vector3f.ZERO;

         // add emitter sample
         radiance = radiance.plus( sampleEmitters( rayDirection, surfacePoint,
            random ) );

         // add recursive reflection
         //
         // single hemisphere sample, ideal diffuse BRDF:
         // reflected = (inradiance * pi) * (cos(in) / pi * color) * reflectance
         // -- reflectance magnitude is 'scaled' by the russian roulette, cos is
         // importance sampled (both done by SurfacePoint), and the pi and 1/pi
         // cancel out
         const next :Object = surfacePoint.getNextDirection( random,
            rayDirection.negative() )
         // check surface bounces ray
         if( next )
         {
            // recurse
            const nextRadiance :Vector3f = getRadiance( surfacePoint.position,
               next.direction, random, surfacePoint.hitId );
            radiance = radiance.plus( nextRadiance.multiply( next.color ) );
         }
      }
      else
      {
         // no hit: default/background scene emission
         radiance = scene_m.getDefaultEmission( rayDirection.negative() );
      }

      return radiance;
   }


/// commands -------------------------------------------------------------------


/// implementation -------------------------------------------------------------
   /**
    * Radiance from an emitter sample.
    *
    * @return radiance back along ray direction
    */
   private function sampleEmitters(
      rayDirection :Vector3f,
      surfacePoint :SurfacePoint,
      random       :RandomMwc ) :Vector3f
   {
      // single emitter sample, ideal diffuse BRDF:
      // reflected = (emitivity * solidangle) * (emitterscount) *
      // (cos(emitdirection) / pi * reflectivity)
      // -- SurfacePoint does the first and last parts (in separate methods)

      // check an emitter was found
      const emitter :Object = scene_m.getEmitter( random );
      if( emitter.id )
      {
         // make direction to emit point
         const emitDirection :Vector3f = emitter.position.minus(
            surfacePoint.position ).unitize();

         // send shadow ray
         const hit :Object = scene_m.getIntersection( surfacePoint.position,
            emitDirection, surfacePoint.hitId );

         // if unshadowed, get inward emission value
         var emissionIn :Vector3f = Vector3f.ZERO;
         if( (null == hit.object) || (emitter.id == hit.object) )
         {
            emissionIn = new SurfacePoint( emitter.id, emitter.position
               ).getEmission( surfacePoint.position, emitDirection.negative(),
               true );
         }

         // get amount reflected by surface
         const radiance :Vector3f = surfacePoint.getReflection( emitDirection,
            emissionIn.multiply( Number(scene_m.emittersCount) ),
            rayDirection.negative() );
      }

      return radiance ? radiance : Vector3f.ZERO;
   }


/// fields ---------------------------------------------------------------------
   private var scene_m :Scene;
}


}
