/*------------------------------------------------------------------------------

   MiniLight Flex : minimal global illumination renderer
   Copyright (c) 2007-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*/




package org.hxa7241.flex.minilight
{


import flash.display.BitmapData;

import org.hxa7241.flex.graphics.Vector3f;


/**
 * Pixel sheet with simple tone-mapping and 'write-through' UI/output bitmap.
 *
 * <p>Stores high-precision values, and writes-through to 32bit platform
 * pixmap.</p>
 *
 * Uses PPM (plain) image format:
 * <cite>http://netpbm.sourceforge.net/doc/ppm.html</cite><br/><br/>
 *
 * <p>Uses Ward simple tonemapper:
 * <cite>'A Contrast Based Scalefactor For Luminance Display'
 * Ward;
 * Graphics Gems 4, AP 1994.</cite></p>
 *
 * @invariants
 * <ul>
 *    <li>pixels_m elements are Vector3f</li>
 *    <li>pixels_m.length == (bitmap_m.width * bitmap_m.height)</li>
 *    <li>sampleCounts_m elements are uint</li>
 *    <li>sampleCounts_m.length == pixels_m.length</li>
 *    <li>all fields not null</li>
 * </ul>
 */
public class Image
{
   public function Image(
      bitmapData :BitmapData )
   {
      // reference external UI bitmap
      bitmap_m = bitmapData;

      // make pixel arrays
      pixels_m       = new Array( int(bitmap_m.width * bitmap_m.height) );
      sampleCounts_m = new Array( pixels_m.length );
      for( var i :uint = 0;  i < pixels_m.length;  ++i )
      {
         pixels_m[i]       = new Vector3f();
         sampleCounts_m[i] = uint(0);
      }
   }


/// queries --------------------------------------------------------------------
   public function get width() :uint
   {
      return bitmap_m.width;
   }


   public function get height() :uint
   {
      return bitmap_m.height;
   }


   /**
    * Image formatted into string (PPM-plain).
    */
   public function get formatted() :String
   {
      // write ID and comment
      var out :Array = [ PPM_PLAIN_ID, '\n', "# ", MINILIGHT_URI, "\n\n" ];

      // write width, height, maxval
      out.push( bitmap_m.width, ' ', bitmap_m.height, '\n', 255, '\n' );

      // write pixels
      var column :uint = 0;
      for( var i :uint = 0;  i < pixels_m.length;  ++i )
      {
         // apply function to each channel of pixel
         convertPixel( i, function( c :uint, byte :uint ) :void
            {
               // output as text (in lines of no more than 70 chars)
               const s :String = byte.toString();
               if( (column + 1 + s.length) <= 70 )
               {
                  // (don't put space before very first value)
                  out.push( ((0 != column) || (0 != i) ? ' ' : ''), s );
                  column += 1 + s.length;
               }
               else
               {
                  out.push( '\n', s );
                  column = s.length;
               }
            } );
      }

      return out.join( '' );
   }


/// commands -------------------------------------------------------------------
   /**
    * Accumulate (add, not just assign) a value to the image.
    */
   public function addToPixel(
      x        :uint,
      y        :uint,
      radiance :Vector3f ) :void
   {
      // ignore values with out-of-range coords
      if( (x >= 0) && (x < bitmap_m.width) && (y >= 0) && (y < bitmap_m.height))
      {
         const yInv  :uint = bitmap_m.height - 1 - y;
         const index :uint = x + (yInv * bitmap_m.width);

         // accumulate pixel
         pixels_m[ index ]       = pixels_m[ index ].plus( radiance );
         sampleCounts_m[ index ] = sampleCounts_m[ index ] + uint(1);

         // update output copy
         updateBitmap( x, yInv );
      }
   }


   /**
    * Recalculate tone mapping, and update UI/output bitmap.
    */
   public function updateMapping() :void
   {
      // make new tonemap scaling
      toneMapping_m = calculateToneMapping( pixels_m, sampleCounts_m );

      bitmap_m.lock();

      // update output pixels
      for( var y :uint = 0;  y < bitmap_m.height;  ++y )
      {
         for( var x :uint = 0;  x < bitmap_m.width;  ++x )
         {
            // map pixel value
            updateBitmap( x, y );
         }
      }

      bitmap_m.unlock();
   }


/// implementation -------------------------------------------------------------
   /**
    * Copy pixel to UI/output bitmap.
    */
   protected function updateBitmap(
      x :uint,
      y :uint ) :void
   {
      // combine channels into a dword (with opaque alpha)
      var argb :uint = 0xFF000000;
      const index :uint = x + (y * bitmap_m.width);
      convertPixel( index, function( c :uint, byte :uint ) :void
         {
            // or byte into dword
            argb |= byte << ((2 - c) << 3);
         } );

      // write output copy
      bitmap_m.setPixel32( x, y, argb );
   }


   /**
    * Convert pixel to three bytes.
    *
    * @param takeChannel :function( index :uint, byte :uint ) :void
    */
   protected function convertPixel(
      index       :uint,
      takeChannel :Function ) :void
   {
      // read pixel value
      const value :Vector3f = pixels_m[ index ].divide(
         Number(sampleCounts_m[ index ]) );

      // step through channels
      for( var c :uint = 0;  c < 3;  ++c )
      {
         // tonemap, gamma encode, quantize
         var mapped :Number = value.get(c) * toneMapping_m;
         mapped = Math.pow( (mapped > 0.0 ? mapped : 0.0), GAMMA_ENCODE );
         mapped = Math.floor( (mapped * 255.0) + 0.5 );

         // yield byte
         takeChannel( c, uint(mapped <= 255.0 ? mapped : 255.0) );
      }
   }


   /**
    * Calculate tone-mapping scaling factor.
    *
    * @param pixels elements are Vector3f
    * @param counts elements are Number
    */
   protected static function calculateToneMapping(
      pixels :Array,
      counts :Array ) :Number
   {
      // calculate log mean luminance of pixel values

      var sumOfLogs :Number = 0.0;
      for( var i :uint = pixels.length;  i-- > 0; )
      {
         const Y :Number = pixels[i].dot( RGB_LUMINANCE ) / Number(counts[i]);
         sumOfLogs += Math.log( Y > 1e-4 ? Y : 1e-4 ) * Math.LOG10E;
      }

      const logMeanLuminance :Number = Math.pow( 10.0, sumOfLogs /
         Number(pixels.length) );

      // (what do these mean again? (still haven't checked the tech paper...))
      const a :Number = 1.219 + Math.pow( DISPLAY_LUMINANCE_MAX * 0.25, 0.4 );
      const b :Number = 1.219 + Math.pow( logMeanLuminance, 0.4 );

      return Math.pow( a / b, 2.5 ) / DISPLAY_LUMINANCE_MAX;
   }


/// constants ------------------------------------------------------------------
   // guess of average screen maximum brightness
   private static const DISPLAY_LUMINANCE_MAX :Number = 200.0;

   // ITU-R BT.709 standard RGB luminance weighting
   private static const RGB_LUMINANCE :Vector3f = new Vector3f(
      0.2126, 0.7152, 0.0722 );

   // ITU-R BT.709 standard gamma
   private static const GAMMA_ENCODE :Number = 0.45;

   // format strings
   private static const PPM_PLAIN_ID  :String = "P3";
   private static const MINILIGHT_URI :String =
      "http://www.hxa7241.org/minilight/";


/// fields ---------------------------------------------------------------------
   private var pixels_m        :Array;
   private var sampleCounts_m  :Array;
   private var toneMapping_m   :Number = 0.01;

   private var bitmap_m        :BitmapData;
}


}
