/*------------------------------------------------------------------------------

   MiniLight Flex : minimal global illumination renderer
   Copyright (c) 2007-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*/




package org.hxa7241.flex.graphics
{


//import org.hxa7241.flex.general.Basics;
import org.hxa7241.flex.general.StringStreamIn;


/**
 * Yes, its the 3D vector class!.
 *
 * <p>...mostly the usual sort of stuff.</p>
 *
 * <p>(Unused methods are commented out.)</p>
 *
 * <p>Constant (But promise not to write to x,y,z fields!).</p>
 */
public final class Vector3f
{
   /**
    * @parameters can be one of:
    * <ul>
    *    <li>nothing</li>
    *    <li>a StringStreamIn with content in the format (0.0 0.0 0.0)</li>
    *    <li>one or more objects</li>
    *    <li>an Array of objects</li>
    *    <li>another Vector3f</li>
    * </ul>
    */
   public function Vector3f(
      ... args )
   {
      // string stream construction
      if( args[0] is StringStreamIn )
      {
         x = args[0].number();
         y = args[0].number();
         z = args[0].number();
      }
//      // copy construction (won't work: 'is' throws)
//      else if( args[0] is Vector3f )
//      {
//         x = args[0].x;
//         y = args[0].y;
//         z = args[0].z;
//      }
      // conversion construction
      else
      {
         args = (args[0] is Array) ? args[0] : args;

         // duplicate single argument or copy multiple arguments
         // default to zeros
         x = y = z = isNaN(Number(args[0])) ? 0.0 : Number(args[0]);
         if( args.length > 1 )
         {
            y = isNaN(Number(args[1])) ? 0.0 : Number(args[1]);
            z = isNaN(Number(args[2])) ? 0.0 : Number(args[2]);
         }
      }
   }


/// queries --------------------------------------------------------------------
//   public function toString() :String
//   {
//      return "(" + x + " " + y + " " + z + ")";
//   }
//
//
//   public function toArray() :Array
//   {
//      return [ x, y, z ];
//   }


//   public function get x() :Number
//   {
//      return x_m;
//   }
//
//
//   public function get y() :Number
//   {
//      return y_m;
//   }
//
//
//   public function get z() :Number
//   {
//      return z_m;
//   }


   public function get(
      i :uint ) :Number
   {
      // out of range i yields x
      return (2 == i) ? z : ((1 == i) ? y : x);
   }


//   public function sum() :Number
//   {
//      return x + y + z;
//   }
//
//
//   public function average() :Number
//   {
//      const ONE_OVER_3 :Number = 1.0 / 3.0;
//
//      return (x + y + z) * ONE_OVER_3;
//   }
//
//
//   public function smallest() :Number
//   {
//      const a :Number = (x <= y) ? x : y;
//      return (a <= z) ? a : z;
//   }
//
//
//   public function largest() :Number
//   {
//      const a :Number = (x >= y) ? x : y;
//      return (a >= z) ? a : z;
//   }


//   public function length() :Number
//   {
//      return Math.sqrt( (x * x) + (y * y) + (z * z) );
//   }


   public function dot(
      v :Vector3f ) :Number
   {
      return (x * v.x) + (y * v.y) + (z * v.z);
   }


//   public function distance(
//      v :Vector3f ) :Number
//   {
//      const xDif :Number = x - v.x;
//      const yDif :Number = y - v.y;
//      const zDif :Number = z - v.z;
//
//      return Math.sqrt( (xDif * xDif) + (yDif * yDif) + (zDif * zDif) );
//   }


   public function negative() :Vector3f
   {
      return new Vector3f( -x, -y, -z );
   }


//   public function abs() :Vector3f
//   {
//      return new Vector3f( (x >= 0.0) ? x : -x,
//                           (y >= 0.0) ? y : -y,
//                           (z >= 0.0) ? z : -z );
//   }


   public function unitize() :Vector3f
   {
      const length :Number = Math.sqrt(
         (x * x) + (y * y) + (z * z) );
      const oneOverLength :Number = (0.0 != length) ? (1.0 / length) : 0.0;

      return new Vector3f( x * oneOverLength,
                           y * oneOverLength,
                           z * oneOverLength );
   }


   public function cross(
      v :Vector3f ) :Vector3f
   {
      return new Vector3f( (y * v.z) - (z * v.y),
                           (z * v.x) - (x * v.z),
                           (x * v.y) - (y * v.x) );
   }


   public function plus(
      v :Vector3f ) :Vector3f
   {
      return new Vector3f( x + v.x,
                           y + v.y,
                           z + v.z );
   }


   public function minus(
      v :Vector3f ) :Vector3f
   {
      return new Vector3f( x - v.x,
                           y - v.y,
                           z - v.z );
   }


   public function multiply(
      a :* ) :Vector3f
   {
      if( a is Vector3f )
      {
         return new Vector3f( x * a.x,
                              y * a.y,
                              z * a.z );
      }
      else
      {
         return new Vector3f( x * a,
                              y * a,
                              z * a );
      }
   }


   public function divide(
      a :* ) :Vector3f
   {
      if( a is Vector3f )
      {
         return new Vector3f( x / a.x,
                              y / a.y,
                              z / a.z );
      }
      else
      {
         const oneOverN :Number = 1.0 / a;

         return new Vector3f( x * oneOverN,
                              y * oneOverN,
                              z * oneOverN );
      }
   }


//   public function isEqual(
//      v :Vector3f ) :Boolean
//   {
//      return (x == v.x) && (y == v.y) && (z == v.z);
//   }
//
//
//   public function isNotEqual(
//      v :Vector3f ) :Boolean
//   {
//      return (x != v.x) || (y != v.y) || (z != v.z);
//   }


   public function isZero() :Boolean
   {
      return (0.0 == x) && (0.0 == y) && (0.0 == z);
   }


//   // returning vectors of -1.0 or 0.0 or +1.0
//   public function sign() :Vector3f
//   {
//      return compare( Vector3f.ZERO );
//   }
//
//
//   public function compare(
//      v :Vector3f ) :Vector3f
//   {
//      return new Vector3f(
//         x > v.x ? +1.0 : (x == v.x ? 0.0 : -1.0),
//         y > v.y ? +1.0 : (y == v.y ? 0.0 : -1.0),
//         z > v.z ? +1.0 : (z == v.z ? 0.0 : -1.0) );
//   }
//
//
//   // returning vectors of Number(Boolean)
//   public function equal(
//      v :Vector3f ) :Vector3f
//   {
//      return new Vector3f( Number(x == v.x),
//                           Number(y == v.y),
//                           Number(z == v.z) );
//   }
//
//
//   public function larger(
//      v :Vector3f ) :Vector3f
//   {
//      return new Vector3f( Number(x > v.x),
//                           Number(y > v.y),
//                           Number(z > v.z) );
//   }
//
//
//   public function largerEqual(
//      v :Vector3f ) :Vector3f
//   {
//      return new Vector3f( Number(x >= v.x),
//                           Number(y >= v.y),
//                           Number(z >= v.z) );
//   }
//
//
//   public function smaller(
//      v :Vector3f ) :Vector3f
//   {
//      return new Vector3f( Number(x < v.x),
//                           Number(y < v.y),
//                           Number(z < v.z) );
//   }
//
//
//   public function smallerEqual(
//      v :Vector3f ) :Vector3f
//   {
//      return new Vector3f( Number(x <= v.x),
//                           Number(y <= v.y),
//                           Number(z <= v.z) );
//   }


//   /**
//    * 0 to almost 1, ie: [0,1).
//    */
//   public function getClamped01() :Vector3f
//   {
//      return new Vector3f(
//         x < 1.0 ? (x >= 0.0 ? x : 0.0) : Basics.NUMBER_ALMOST_ONE,
//         y < 1.0 ? (y >= 0.0 ? y : 0.0) : Basics.NUMBER_ALMOST_ONE,
//         z < 1.0 ? (z >= 0.0 ? z : 0.0) : Basics.NUMBER_ALMOST_ONE );
//   }


   public function getClamped(
      min :Vector3f,
      max :Vector3f ) :Vector3f
   {
      return new Vector3f(
         x <= max.x ? (x >= min.x ? x : min.x) : max.x,
         y <= max.y ? (y >= min.y ? y : min.y) : max.y,
         z <= max.z ? (z >= min.z ? z : min.z) : max.z );
   }


/// commands -------------------------------------------------------------------
//   public function set(
//      a :Number,
//      b :Number,
//      c :Number ) :Vector3f
//   {
//      x = a;
//      y = b;
//      z = c;
//
//      return this;
//   }
//
//
//   public function set xyz(
//      xyz :Array ) :void
//   {
//      x = isNaN(Number(xyz[0])) ? 0.0 : Number(xyz[0]);
//      y = isNaN(Number(xyz[1])) ? 0.0 : Number(xyz[1]);
//      z = isNaN(Number(xyz[2])) ? 0.0 : Number(xyz[2]);
//   }
//
//
//   public function negateEq() :Vector3f
//   {
//      x = -x;
//      y = -y;
//      z = -z;
//
//      return this;
//   }
//
//
//   public function absEq() :Vector3f
//   {
//      if( x < 0.0 )
//      {
//         x = -x;
//      }
//      if( y < 0.0 )
//      {
//         y = -y;
//      }
//      if( z < 0.0 )
//      {
//         z = -z;
//      }
//
//      return this;
//   }
//
//
//   public function unitizeEq() :Vector3f
//   {
//      const length :Number = Math.sqrt(
//         (x * x) + (y * y) + (z * z) );
//      const oneOverLength :Number = (0.0 != length) ? (1.0 / length) : 0.0;
//
//      x *= oneOverLength;
//      y *= oneOverLength;
//      z *= oneOverLength;
//
//      return this;
//   }
//
//
//   public function crossEq(
//      v :Vector3f ) :Vector3f
//   {
//      const a :Number = (y * v.z) - (z * v.y);
//      const b :Number = (z * v.x) - (x * v.z);
//      const c :Number = (x * v.y) - (y * v.x);
//
//      x = a;
//      y = b;
//      z = c;
//
//      return this;
//   }
//
//
//   public function plusEq(
//      v :Vector3f ) :Vector3f
//   {
//      x += v.x;
//      y += v.y;
//      z += v.z;
//
//      return this;
//   }
//
//
//   public function minusEq(
//      v :Vector3f ) :Vector3f
//   {
//      x -= v.x;
//      y -= v.y;
//      z -= v.z;
//
//      return this;
//   }
//
//
//   public function multiplyEq(
//      a :* ) :Vector3f
//   {
//      if( a is Vector3f )
//      {
//         x *= a.x;
//         y *= a.y;
//         z *= a.z;
//      }
//      else if( a is Number )
//      {
//         x *= a;
//         y *= a;
//         z *= a;
//      }
//
//      return this;
//   }
//
//
//   public function divideEq(
//      a :* ) :Vector3f
//   {
//      if( a is Vector3f )
//      {
//         x /= a.x;
//         y /= a.y;
//         z /= a.z;
//      }
//      else if( a is Number )
//      {
//         const oneOverN :Number = 1.0 / a;
//
//         x *= oneOverN;
//         y *= oneOverN;
//         z *= oneOverN;
//      }
//
//      return this;
//   }
//
//
//   public function clampMin(
//      min :Vector3f ) :Vector3f
//   {
//      if( x < min.x )
//      {
//         x = min.x;
//      }
//      if( y < min.y )
//      {
//         y = min.y;
//      }
//      if( z < min.z )
//      {
//         z = min.z;
//      }
//
//      return this;
//   }
//
//
//   public function clampMax(
//      max :Vector3f ) :Vector3f
//   {
//      if( x > max.x )
//      {
//         x = max.x;
//      }
//      if( y > max.y )
//      {
//         y = max.y;
//      }
//      if( z > max.z )
//      {
//         z = max.z;
//      }
//
//      return this;
//   }
//
//
//   public function clamp(
//      min :Vector3f,
//      max :Vector3f ) :Vector3f
//   {
//      if( x > max.x )
//         x = max.x;
//      else
//      if( x < min.x )
//         x = min.x;
//
//      if( y > max.y )
//         y = max.y;
//      else
//      if( y < min.y )
//         y = min.y;
//
//      if( z > max.z )
//         z = max.z;
//      else
//      if( z < min.z )
//         z = min.z;
//
//      return this;
//   }
//
//
//   /**
//    * 0 to almost 1, ie: [0,1).
//    */
//   public function clamp01() :Vector3f
//   {
//      if( x >= 1.0 )
//         x  = Basics.NUMBER_ALMOST_ONE;
//      else
//      if( x < 0.0 )
//         x = 0.0;
//
//      if( y >= 1.0 )
//         y  = Basics.NUMBER_ALMOST_ONE;
//      else
//      if( y < 0.0 )
//         y = 0.0;
//
//      if( z >= 1.0 )
//         z  = Basics.NUMBER_ALMOST_ONE;
//      else
//      if( z < 0.0 )
//         z = 0.0;
//
//      return this;
//   }


/// constants ------------------------------------------------------------------
   public static const ZERO       :Vector3f = new Vector3f();
//   public static const HALF       :Vector3f = new Vector3f( 0.5 );
   public static const ONE        :Vector3f = new Vector3f( 1.0 );
//   public static const EPSILON    :Vector3f = new Vector3f(
//      Basics.NUMBER_EPSILON );
//   public static const ALMOST_ONE :Vector3f = new Vector3f(
//      Basics.NUMBER_ALMOST_ONE );
   public static const MIN    :Vector3f = new Vector3f( -Number.MAX_VALUE );
   public static const MAX    :Vector3f = new Vector3f( Number.MAX_VALUE );
//   public static const SMALL      :Vector3f = new Vector3f(
//      Basics.NUMBER_SMALL );
//   public static const LARGE      :Vector3f = new Vector3f(
//      Basics.NUMBER_LARGE );
//   public static const X          :Vector3f = new Vector3f( 1.0, 0.0, 0.0 );
//   public static const Y          :Vector3f = new Vector3f( 0.0, 1.0, 0.0 );
//   public static const Z          :Vector3f = new Vector3f( 0.0, 0.0, 1.0 );


/// fields ---------------------------------------------------------------------
   // reading public fields is much faster than using getters
   public var x :Number;
   public var y :Number;
   public var z :Number;
}


}
