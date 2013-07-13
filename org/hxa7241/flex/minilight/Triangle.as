/*------------------------------------------------------------------------------

   MiniLight Flex : minimal global illumination renderer
   Copyright (c) 2007-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*/




package org.hxa7241.flex.minilight
{


import org.hxa7241.flex.general.StringStreamIn;
import org.hxa7241.flex.general.RandomMwc;
import org.hxa7241.flex.graphics.Vector3f;


/**
 * A simple, explicit/non-vertex-shared triangle.
 *
 * <p>Includes geometry and quality.</p>
 *
 * <p>Constant.</p>
 *
 * @implementation
 * Adapts ray intersection code from:
 * <cite>'Fast, Minimum Storage Ray-Triangle Intersection'
 * Moller, Trumbore;
 * Journal of Graphics Tools, v2 n1 p21, 1997.
 * http://www.acm.org/jgt/papers/MollerTrumbore97/</cite>
 *
 * @invariants
 * <ul>
 *    <li>vertexs_m elements are Vector3f</li>
 *    <li>vertexs_m.length = 3</li>
 *    <li>reflectivity_m >= 0 and <= 1</li>
 *    <li>emitivity_m    >= 0</li>
 *    <li>all fields not null</li>
 * </ul>
 */
public class Triangle
{
   public function Triangle(
      modelFile :StringStreamIn )
   {
      // read geometry
      for( var i :uint = 0;  i < 3;  ++i )
      {
         vertexs_m[i] = new Vector3f(modelFile);
      }

      // read and condition quality
      reflectivity_m = new Vector3f( modelFile ).getClamped(
         Vector3f.ZERO, Vector3f.ONE );
      emitivity_m = new Vector3f( modelFile ).getClamped(
         Vector3f.ZERO, Vector3f.MAX );
   }


/// queries --------------------------------------------------------------------
   /**
    * Axis-aligned bounding box of triangle.
    *
    * @return Array of 6 Number, lower corner in [0..2], and upper corner in
    * [3..5]
    */
   public function get bound() :Array
   {
      // initialize
      var bound :Array = new Array( 6 );
      for( var i :uint = 6;  i-- > 0;  bound[i] = vertexs_m[2].get(i % 3) );

      // expand
      for each ( var vertex :Vector3f in vertexs_m )
      {
         for( var j :uint = 6;  j-- > 0; )
         {
            const d :uint = j / 3,  m :uint = j % 3;

            // include some tolerance
            const v :Number = vertex.get(m) + ((0 != d ? 1.0 : -1.0) *
               (Math.abs(vertex.get(m)) + 1.0) * TOLERANCE);
            bound[j] = uint(bound[j] > v) ^ d ? v : bound[j];
         }
      }

      return bound;
   }


   /**
    * Intersection point of ray with triangle.
    *
    * @return hitDistance :Number distance of hit or infinity if no hit
    *
    * @implementation
    * Adapted from:
    * <cite>'Fast, Minimum Storage Ray-Triangle Intersection'
    * Moller, Trumbore;
    * Journal Of Graphics Tools, v2n1p21, 1997.
    * http://www.acm.org/jgt/papers/MollerTrumbore97/</cite>
    *
    * <p>Manually inlined all vector operations (is much faster).</p>
    */
   public function getIntersection(
      rayOrigin    :Vector3f,
      rayDirection :Vector3f ) :Number
   {
      const v0 :Vector3f = vertexs_m[0];
      const v1 :Vector3f = vertexs_m[1];
      const v2 :Vector3f = vertexs_m[2];

      // find vectors for two edges sharing vert0
      //const edge1 :Vector3f = vertexs_m[1].minus( vertexs_m[0] );
      //const edge2 :Vector3f = vertexs_m[2].minus( vertexs_m[0] );
      const e1x :Number = v1.x - v0.x;
      const e1y :Number = v1.y - v0.y;
      const e1z :Number = v1.z - v0.z;
      const e2x :Number = v2.x - v0.x;
      const e2y :Number = v2.y - v0.y;
      const e2z :Number = v2.z - v0.z;

      // begin calculating determinant - also used to calculate U parameter
      //const pvec :Vector3f = rayDirection.cross( edge2 );
      const pvx :Number = (rayDirection.y * e2z) - (rayDirection.z * e2y);
      const pvy :Number = (rayDirection.z * e2x) - (rayDirection.x * e2z);
      const pvz :Number = (rayDirection.x * e2y) - (rayDirection.y * e2x);

      // if determinant is near zero, ray lies in plane of triangle
      //const det :Number = edge1.dot( pvec );
      const det :Number = (e1x * pvx) + (e1y * pvy) + (e1z * pvz);

      const EPSILON :Number = 0.000001;
      if( (det > -EPSILON) && (det < EPSILON) )
      {
         return Infinity;
      }

      const inv_det :Number = 1.0 / det;

      // calculate distance from vertex 0 to ray origin
      //const tvec :Vector3f = rayOrigin.minus( v0 );
      const tvx :Number = rayOrigin.x - v0.x;
      const tvy :Number = rayOrigin.y - v0.y;
      const tvz :Number = rayOrigin.z - v0.z;

      // calculate U parameter and test bounds
      //const u :Number = tvec.dot( pvec ) * inv_det;
      const u :Number = ((tvx * pvx) + (tvy * pvy) + (tvz * pvz)) * inv_det;
      if( (u < 0.0) || (u > 1.0) )
      {
         return Infinity;
      }

      // prepare to test V parameter
      //const qvec :Vector3f = tvec.cross( edge1 );
      const qvx :Number = (tvy * e1z) - (tvz * e1y);
      const qvy :Number = (tvz * e1x) - (tvx * e1z);
      const qvz :Number = (tvx * e1y) - (tvy * e1x);

      // calculate V parameter and test bounds
      //const v :Number = rayDirection.dot( qvec ) * inv_det;
      const v :Number = ((rayDirection.x * qvx) +
         (rayDirection.y * qvy) + (rayDirection.z * qvz)) * inv_det;
      if( (v < 0.0) || (u + v > 1.0) )
      {
         return  Infinity;
      }

      // calculate t, ray intersects triangle
      //const hitDistance :Number = edge2.dot( qvec ) * inv_det;
      const hitDistance :Number = ((e2x * qvx) + (e2y * qvy) + (e2z * qvz)) *
         inv_det;

      // only allow intersections in the forward ray direction
      return hitDistance >= 0.0 ? hitDistance : Infinity;
   }


   /**
    * Monte-carlo sample point on triangle.
    */
   public function getSamplePoint(
      random :RandomMwc ) :Vector3f
   {
      // get two randoms
      const sqr1 :Number = Math.sqrt( random.float );
      const r2   :Number = random.float;

      // make barycentric coords
      const a :Number = 1.0 - sqr1;
      const b :Number = (1.0 - r2) * sqr1;
      //const c :Number = r2 * sqr1;

      // make position from barycentrics:
      // calculate interpolation by using two edges as axes scaled by the
      // barycentrics
      return ( vertexs_m[1].minus(vertexs_m[0]).multiply(a) ).plus(
         vertexs_m[2].minus(vertexs_m[0]).multiply(b) ).plus( vertexs_m[0] );
   }


   public function get normal() :Vector3f
   {
      return tangent.cross( vertexs_m[2].minus(vertexs_m[1]) ).unitize();
   }


   public function get tangent() :Vector3f
   {
      return vertexs_m[1].minus(vertexs_m[0]).unitize();
   }


   public function get area() :Number
   {
      // half area of parallelogram
      const pa2 :Vector3f = vertexs_m[1].minus( vertexs_m[0] ).cross(
         vertexs_m[2].minus(vertexs_m[1]) );
      return Math.sqrt( pa2.dot(pa2) ) * 0.5;
   }


   public function get reflectivity() :Vector3f
   {
      return reflectivity_m;
   }


   public function get emitivity() :Vector3f
   {
      return emitivity_m;
   }


/// commands -------------------------------------------------------------------


/// constants ------------------------------------------------------------------
   // one mm seems reasonable...
   public static const TOLERANCE :Number = 1.0 / 1024.0;


/// fields ---------------------------------------------------------------------
   // geometry
   private const vertexs_m :Array = new Array( 3 );

   // quality
   private var reflectivity_m :Vector3f;
   private var emitivity_m    :Vector3f;
}


}
