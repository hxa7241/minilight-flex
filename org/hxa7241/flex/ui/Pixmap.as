/*------------------------------------------------------------------------------

   HXA7241 Flex library
   Copyright (c) 2007, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*/




package org.hxa7241.flex.ui
{


import flash.display.BitmapData;
import flash.display.Bitmap;
import mx.core.UIComponent;


public class Pixmap extends UIComponent
{
   public function Pixmap()
   {
   }


/// commands -------------------------------------------------------------------
   public function set scale(
      s :Number ) :void
   {
      if( s > 0.0 )
      {
         bitmap_m.scaleX = s;
         bitmap_m.scaleY = s;
      }
   }


   override protected function createChildren() :void
   {
      addChild( bitmap_m );
   }


   /*override protected function updateDisplayList(
      width  :Number,
      height :Number ) :void
   {
      super.updateDisplayList( width, height );

      //const border       :uint = getStyle( "borderThickness" ) * 2;
      //const bitmapWidth  :int  = Math.max( 1, width  - border );
      //const bitmapHeight :int  = Math.max( 1, height - border );
      //
      //bitmap_m.bitmapData = new BitmapData( bitmapWidth, bitmapHeight,
      //   bitmap_m.bitmapData.transparent, 0 );

      bitmap_m.bitmapData = new BitmapData( width, height,
         bitmap_m.bitmapData.transparent, 0 );
   }*/


   public function setBitmapSize(
      width  :uint,
      height :uint ) :void
   {
      // clamp within UIComponent, preserving aspect ratio:
      // scale both by smaller needed shrink-factor
      const wShrink :Number = Number(this.width)  / (Number(width) *
         bitmap_m.scaleX);
      const hShrink :Number = Number(this.height) / (Number(height) *
         bitmap_m.scaleY);
      const shrink  :Number = wShrink < hShrink ? wShrink : hShrink;
      if( shrink < 1.0 )
      {
         // must round-off: in case (a/b)*b < a
         width  = uint( (Number(width)  * shrink) + 0.5 );
         height = uint( (Number(height) * shrink) + 0.5 );
      }

      // make new bitmapData
      bitmap_m.bitmapData = new BitmapData( width, height,
         bitmap_m.bitmapData.transparent, 0 );
   }


/// queries --------------------------------------------------------------------
   public function get bitmapData() :BitmapData
   {
      return bitmap_m.bitmapData;
   }


/// fields ---------------------------------------------------------------------
   private var bitmap_m :Bitmap = new Bitmap( new BitmapData( 1, 1, true, 0 ) );
}


}
