// --------------------------------------------------------------------
//	圧縮機
// ====================================================================
//	8th/Dec.2021  t.hara
// --------------------------------------------------------------------

#include <fstream>
#include <string>
#include "compressor.hpp"
#include "cbitmap.hpp"

static const int logo_width = 422;
static const int logo_height = 80;
static const int logo_byte_width = ( logo_width * 3 + 3 ) & ~3;

// --------------------------------------------------------------------
static void set_palette( cbitmap &decode, int &index, int d ){
	const unsigned char palette[ 4 ][ 3 ] = {
		{ 0, 0, 0 },			// 黒
		{ 192, 0, 0 },			// 青
		{ 128, 128, 128 },		// 灰色
		{ 255, 255, 255 },		// 白
	};
	int x, y;

	x = index % logo_width;
	y = index / logo_width;
	decode.set_pixel( x, y, palette[ d ][ 0 ], palette[ d ][ 1 ], palette[ d ][ 2 ] );
	index++;
}

// --------------------------------------------------------------------
void ccompressor::decompress( cbitmap &decode ){
	int decode_index, compressed_index, i, c, d, pixel_count;
	unsigned char current_color, gray, has_next;

	pixel_count = logo_width * logo_height;
	decode.alloc( logo_width, logo_height );
	compressed_index = 0;
	decode_index = 0;
	current_color = 0;
	while( decode_index < pixel_count ){
		d = compressed[ compressed_index++ ];
		if( ( d & 0x01 ) != 0 ){
			//	3画素以下の場合は、[N][C3][C2][C1][1] を使う
			d >>= 1;
			for( i = 0; i < 3; i++ ){
				c = d & 3;
				d >>= 2;
				set_palette( decode, decode_index, c );
				if( decode_index >= pixel_count ){
					break;
				}
			}
			current_color = (d & 1) * 3;
		}
		else{
			//	4画素以上の場合は、[XXXXXX][?][0]
			gray = d & 0x02;
			d = (d >> 2) & 63;
			has_next = (d == 0);
			if( d == 0 ){
				d = 63;
			}
			while( decode_index < pixel_count ){
				while( d ){
					set_palette( decode, decode_index, current_color );
					if( decode_index >= pixel_count ){
						break;
					}
					d--;
				}
				if( !has_next ){
					break;
				}
				d = compressed[ compressed_index++ ];
				has_next = ( d == 0 );
				if( d == 0 ){
					d = 255;
				}
			}
			if( gray ){
				if( decode_index < pixel_count ){
					set_palette( decode, decode_index, 2 );
				}
			}
			current_color = current_color ^ 3;
		}
	}
}

// --------------------------------------------------------------------
void ccompressor::converter( const cbitmap &bmp ){
	int x, y;
	unsigned char r, g, b;
	double d;
	unsigned char p;

	for( y = 0; y < logo_height; y++ ){
		for( x = 0; x < logo_width; x++ ){
			bmp.get_pixel( x, y, r, g, b );
			d = sqrt( ( r / 255. * r / 255. + g / 255. * g / 255. + b / 255. * b / 255. ) / 3. );
			if( d < 0.25 ){
				p = 0;		//	black
			}
			else if( d < 0.75 ){
				p = 2;		//	gray
			}
			else{
				p = 3;		//	white
			}
			this->image.push_back( p );
		}
	}
}

// --------------------------------------------------------------------
unsigned char ccompressor::get( int index ){

	if( index < 0 || index >= (int)this->image.size() ){
		return 0;
	}
	return this->image[ index ];
}

// --------------------------------------------------------------------
void ccompressor::run( void ){
	int index = 0;
	int i;
	unsigned char current_color = 0, c;

	while( index < (int)this->image.size() ) {
		if( this->image[ index ] == current_color ){
			//	何画素続いているか調べる
			i = 0;
			while( ((index + i) < (int)this->image.size()) && (this->image[ index + i ] == current_color) ) {
				i++;
			}
			if( ((index % logo_width) == 44) && ((index / logo_width) == 53) ){
				index = index;
			}
			if( i <= 3 ) {
				//	3画素以下の場合は、[N][C3][C2][C1][1] を使う
				c = (( this->get( index + 0 ) << 1 ) | ( this->get( index + 1 ) << 3 ) | ( this->get( index + 2 ) << 5 ));
				current_color = this->get( index + 3 );
				c |= (unsigned char)((( current_color << 6 ) & 0x80 ) | 1 );
				index += 3;
				this->compressed.push_back( c );
			}
			else{
				//	4画素以上の場合は、[XXXXXX][?][0]
				c = 0x00;
				if( this->get( index + i ) == 2 ){
					c = c | 0x02;
					index++;
				}
				index += i;
				if( i < 64 ){
					c |= (unsigned char)( i << 2 );
					this->compressed.push_back( c );
				}
				else{
					this->compressed.push_back( c );
					i = i - 63;
					while( i ){
						if( i < 256 ){
							this->compressed.push_back( i );
							break;
						}
						else{
							this->compressed.push_back( 0 );
							i = i - 255;
						}
					}
				}
			}
			current_color = 3 - current_color;
		}
		else{
			//	グレーの場合は、[N][C3][C2][C1][1] を使う
			c = ( ( this->get( index + 0 ) << 1 ) | ( this->get( index + 1 ) << 3 ) | ( this->get( index + 2 ) << 5 ) );
			current_color = this->get( index + 3 );
			c |= (unsigned char)((( current_color << 6 ) & 0x80 ) | 1 );
			index += 3;
			this->compressed.push_back( c );
		}
	}
}

// --------------------------------------------------------------------
void ccompressor::save( const char *p_file_name ){
	std::ofstream file( p_file_name, std::ios::binary );

	if( !file ){
		throw ( "Cannot create the '" + std::string( p_file_name ) + "'." );
	}

	file.write( (char*)(this->compressed.data()), this->compressed.size() );
	file.close();
}
