/*------------------------------------------------------------------------------

   MiniLight Flex : minimal global illumination renderer
   Copyright (c) 2007-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*/




package org.hxa7241.flex.general
{


import flash.errors.EOFError;
import mx.utils.StringUtil;


/**
 * A stream-reading wrapper for a string.
 *
 * <p>Designed after C++ streaming: roughly, 'objects' separated by blanks.</p>
 *
 * <p>Constant.</p>
 *
 * @implementation
 * <p>RegExps seemed to be extremely (unusably) slow for a 70KB string.</p>
 *
 * @invariants
 * <ul>
 *    <li>string_m not null</li>
 *    <li>position_m <= string_m.length</li>
 * </ul>
 */
public class StringStreamIn
{
   public function StringStreamIn(
      string :String )
   {
      string_m   = string ? string : "";
      position_m = 0;
   }


/// queries --------------------------------------------------------------------


/// commands -------------------------------------------------------------------
   /**
    * Read next Number after any leading blanks (and advance stream position).
    *
    * @throws TypeError if a Number is not there
    * @throws EOFError if end of string reached before any object
    */
   public function number() :Number
   {
      // move past separator to find token start, and throw for eof
      while( !isToken( string_m.charAt( position_m++ ) ) );
      const tokenStart :uint = --position_m;
      if( tokenStart >= string_m.length )
      {
         throw new EOFError();
      }

      // move past token to separator to find token end
      while( (position_m < string_m.length) &&
         isToken( string_m.charAt( position_m++ ) ) );
      const tokenEnd :uint = --position_m;

      // convert token to Number, or throw
      const n :Number = parseFloat( string_m.substring(tokenStart, tokenEnd) );
      if( isNaN( n ) )
      {
         throw new TypeError( "Incorrect object in stream read." );
      }

      return n;
   }


/// implementation -------------------------------------------------------------
   private function isToken(
      c :String ) :Boolean
   {
      // separator chars are defined as blanks and parentheses
      return !(StringUtil.isWhitespace( c ) || (c == "(") || (c == ")") );
   }


/// fields ---------------------------------------------------------------------
   private var string_m   :String;
   private var position_m :uint;
}


}
