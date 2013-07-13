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
 * A View with rasterization capability.
 *
 * <p>getPixel() accumulates a pixel to the image.</p>
 *
 * <p>Constant.</p>
 *
 * @invariants
 * <ul>
 *    <li>viewAngle_m is >= 10 and <= 160 degrees in radians</li>
 *    <li>viewDirection_m is unitized</li>
 *    <li>right_m is unitized</li>
 *    <li>up_m is unitized</li>
 *    <li>above three form a coordinate frame</li>
 * </ul>
 */
public class Camera
{
   public function Camera(
      modelFile :StringStreamIn )
   {
      // read and condition view definition

      viewPosition_m = new Vector3f( modelFile );

      viewDirection_m = new Vector3f( modelFile ).unitize();
      viewDirection_m = viewDirection_m.isZero() ?
         new Vector3f( 0.0, 0.0, 1.0 ) : viewDirection_m;

      viewAngle_m = modelFile.number();
      viewAngle_m = (viewAngle_m < 10.0 ? 10.0 : (viewAngle_m > 160.0 ?
         160.0 : viewAngle_m)) * (Math.PI / 180.0);

      // make other directions of frame
      up_m    = new Vector3f( 0.0, 1.0, 0.0 );
      right_m = up_m.cross( viewDirection_m ).unitize();

      if( !right_m.isZero() )
      {
         up_m = viewDirection_m.cross( right_m ).unitize();
      }
      else
      {
         up_m = new Vector3f( 0.0, 0.0, (viewDirection_m.y < 0.0 ? 1.0 : -1.0));
         right_m = up_m.cross( viewDirection_m ).unitize();
      }
   }


/// queries --------------------------------------------------------------------
   public function get eyePoint() :Vector3f
   {
      return viewPosition_m;
   }


   /**
    * Accumulate a new pixel to the image.
    *
    * @param scene to read from
    * @param image to write to
    */
   public function getPixel(
      scene  :Scene,
      x      :uint,
      y      :uint,
      random :RandomMwc,
      image  :Image ) :void
   {
      const rayTracer :RayTracer = new RayTracer( scene );

      // make image plane displacement vector coefficients
      const xF :Number = ((x + random.float) * 2.0 / image.width ) - 1.0;
      const yF :Number = ((y + random.float) * 2.0 / image.height) - 1.0;

      // make image plane offset vector
      const offset :Vector3f = right_m.multiply(xF).plus(
         up_m.multiply(yF * (Number(image.height) / Number(image.width))) );

      // make sample ray direction (stratified by pixels)
      const sampleDirection :Vector3f = viewDirection_m.plus(
         offset.multiply( Math.tan(viewAngle_m * 0.5) ) ).unitize();

      // get radiance from RayTracer
      const radiance :Vector3f = rayTracer.getRadiance( viewPosition_m,
         sampleDirection, random );

      // add radiance to image
      image.addToPixel( x, y, radiance );
   }


/// commands -------------------------------------------------------------------


/// fields ---------------------------------------------------------------------
   private var viewPosition_m :Vector3f;
   private var viewAngle_m    :Number;

   // view frame
   private var viewDirection_m :Vector3f;
   private var right_m         :Vector3f;
   private var up_m            :Vector3f;
}


}
