/*------------------------------------------------------------------------------

   MiniLight Flex : minimal global illumination renderer
   Copyright (c) 2007-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*/




package org.hxa7241.flex.general
{


/**
 * Simple, fast, good random number generator (Multiply-with-carry).
 *
 * <p>Perhaps the fastest of any generator that passes the Diehard tests.</p>
 *
 * <p>Constant (sort-of: internally/non-semantically modifying).</p>
 *
 * @implementation
 * Concatenation of following two 16-bit multiply-with-carry generators
 * x(n)=a*x(n-1)+carry mod 2^16 and y(n)=b*y(n-1)+carry mod 2^16, number and
 * carry packed within the same 32 bit integer. Algorithm recommended by
 * Marsaglia. Copyright (c) 2005, Glenn Rhoads.
 * <cite>http://web.archive.org/web/20050213041650/http://
 * paul.rutgers.edu/~rhoads/Code/code.html</cite>
 *
 * @invariants
 * <ul>
 *    <li>SEEDS elements are constant</li>
 *    <li>seeds_m elements are uint</li>
 * </ul>
 */
public class RandomMwc
{
   public function RandomMwc(
      seed :uint = 0 )
   {
      seeds_m[0] = (0 != seed) ? seed : SEEDS[0];
      seeds_m[1] = (0 != seed) ? seed : SEEDS[1];
   }


/// queries --------------------------------------------------------------------
   public function get integer() :uint
   {
      // Use any pair of non-equal numbers from this list for the two constants:
      // 18000 18030 18273 18513 18879 19074 19098 19164 19215 19584
      // 19599 19950 20088 20508 20544 20664 20814 20970 21153 21243
      // 21423 21723 21954 22125 22188 22293 22860 22938 22965 22974
      // 23109 23124 23163 23208 23508 23520 23553 23658 23865 24114
      // 24219 24660 24699 24864 24948 25023 25308 25443 26004 26088
      // 26154 26550 26679 26838 27183 27258 27753 27795 27810 27834
      // 27960 28320 28380 28689 28710 28794 28854 28959 28980 29013
      // 29379 29889 30135 30345 30459 30714 30903 30963 31059 31083

      seeds_m[0] = uint( 18000 * (seeds_m[0] & 0xFFFF) + (seeds_m[0] >>> 16) );
      seeds_m[1] = uint( 30903 * (seeds_m[1] & 0xFFFF) + (seeds_m[1] >>> 16) );

      return (seeds_m[0] << 16) + (seeds_m[1] & 0xFFFF);
   }


   public function get float() :Number
   {
      // has gaps between possible values, because double has more bits than
      // uint
      return Number(integer) / 4294967296.0;
   }


/// commands -------------------------------------------------------------------


/// fields ---------------------------------------------------------------------
   private static const SEEDS :Array = [ uint(521288629), uint(362436069) ];

   private const seeds_m :Array = [ uint(0), uint(0) ];
}


}
