// --------------------------------------------------------------------
//	à≥èkã@
// ====================================================================
//	8th/Dec.2021  t.hara
// --------------------------------------------------------------------

#include <fstream>
#include <string>
#include "compressor.hpp"

static const int logo_width = 422;
static const int logo_height = 80;
static const int logo_byte_width = ( logo_width * 3 + 3 ) & ~3;

// --------------------------------------------------------------------
#pragma pack(1)
typedef struct tagBITMAPFILEHEADER{
	uint8_t bfType0;
	uint8_t bfType1;
	uint32_t bfSize;
	uint16_t bfReserved1;
	uint16_t bfReserved2;
	uint32_t bfOffBits;
} BITMAPFILEHEADER;

typedef struct tagBITMAPINFOHEADER{
	uint32_t biSize;
	int32_t biWidth;
	int32_t biHeight;
	uint16_t biPlanes;
	uint16_t biBitCount;
	uint32_t biCompression;
	uint32_t biSizeImage;
	int32_t biXPelsPerMeter;
	int32_t biYPelsPerMeter;
	uint32_t biClrUsed;
	uint32_t biClrImportant;
} BITMAPINFOHEADER;

const uint32_t BI_RGB = 0;

// --------------------------------------------------------------------
static void set_palette( std::vector<unsigned char> &decode, int &index, int d ){
	const unsigned char palette[ 4 ][ 3 ] = {
		{ 0, 0, 0 },			// çï
		{ 192, 0, 0 },			// ê¬
		{ 128, 128, 128 },		// äDêF
		{ 255, 255, 255 },		// îí
	};
	int x, y, p;

	x = index % logo_width;
	y = index / logo_width;
	p = x * 3 + ( logo_height - y - 1 ) * logo_byte_width;
	decode[ p + 0 ] = palette[ d ][ 0 ];
	decode[ p + 1 ] = palette[ d ][ 1 ];
	decode[ p + 2 ] = palette[ d ][ 2 ];
	index++;
}

// --------------------------------------------------------------------
void ccompressor::decompress( std::vector<unsigned char> &decode ){
	int decode_index, compressed_index, image_size, i, c, d, pixel_count;
	unsigned char current_color, gray, has_next;

	image_size = logo_byte_width * logo_height;
	pixel_count = logo_width * logo_height;
	decode.resize( image_size );
	compressed_index = 0;
	decode_index = 0;
	current_color = 0;
	printf( "decompress ----\n" );
	while( decode_index < pixel_count ){
		printf( "(X,Y) = ( %3d, %3d ) : ", decode_index % logo_width, decode_index / logo_width );
		d = compressed[ compressed_index++ ];
		if( ( d & 0x80 ) == 0 ){
			printf( "FIXED3 %d, %d, %d [%d]\n", ( d >> 5 ) & 3, ( d >> 3 ) & 3, ( d >> 1 ) & 3, d & 1 );
			for( i = 0; i < 3; i++ ){
				c = ( d >> (5 - i*2) ) & 3;
				set_palette( decode, decode_index, c );
				if( decode_index >= pixel_count ){
					break;
				}
			}
			current_color = ( d & 1 ) * 3;
		}
		else{
			printf( "RLE " );
			gray = d & 0x40;
			if( gray ){
				printf( "WITH GRAY " );
			}
			d = d & 63;
			has_next = (d == 0);
			if( d == 0 ){
				d = 63;
			}
			printf( "0x%02X ", d );
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
				printf( "0x%02X ", d );
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
			printf( "\n" );
			current_color = current_color ^ 3;
		}
	}
	std::ofstream f( "decode.bmp", std::ios_base::binary );
	if( !f ){
		return;
	}

	BITMAPFILEHEADER fh;
	BITMAPINFOHEADER ih;

	memset( &fh, 0, sizeof( fh ) );
	fh.bfType0 = 'B';
	fh.bfType1 = 'M';
	fh.bfSize = sizeof( BITMAPFILEHEADER ) + sizeof( BITMAPINFOHEADER ) + decode.size();
	fh.bfOffBits = sizeof( BITMAPFILEHEADER ) + sizeof( BITMAPINFOHEADER );

	memset( &ih, 0, sizeof( ih ) );
	ih.biSize = sizeof( ih );
	ih.biBitCount = 24;
	ih.biCompression = BI_RGB;
	ih.biWidth = logo_width;
	ih.biHeight = logo_height;
	ih.biSizeImage = decode.size();

	f.write( (char *)&fh, sizeof( fh ) );
	f.write( (char *)&ih, sizeof( ih ) );
	f.write( (char *)decode.data(), decode.size() );
	f.close();
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

	printf( "compress---\n" );
	while( index < (int)this->image.size() ) {
		printf( "(X,Y) = ( %3d, %3d ) : ", index % logo_width, index / logo_width );
		if( this->image[ index ] == current_color ){
			//	âΩâÊëfë±Ç¢ÇƒÇ¢ÇÈÇ©í≤Ç◊ÇÈ
			i = 0;
			while( ((index + i) < (int)this->image.size()) && (this->image[ index + i ] == current_color) ) {
				i++;
			}
			if( ((index % logo_width) == 44) && ((index / logo_width) == 53) ){
				index = index;
			}
			if( i <= 3 ) {
				//	3âÊëfà»â∫ÇÃèÍçáÇÕÅA[0][C1][C2][C3][N] ÇégÇ§
				c = (( this->get( index + 0 ) << 5 ) | ( this->get( index + 1 ) << 3 ) | ( this->get( index + 2 ) << 1 ));
				current_color = this->get( index + 3 );
				c = c | ( (unsigned char)current_color >> 1 );
				index += 3;
				this->compressed.push_back( c );
				printf( "FIXED3 %d, %d, %d [%d]\n", (c >> 5) & 3, (c >> 3) & 3, (c >> 1) & 3, c & 1 );
			}
			else{
				//	4âÊëfà»è„ÇÃèÍçáÇÕÅA[1][?][XXXXXX]
				printf( "RLE (%d)", i );
				c = 0x80;
				if( this->get( index + i ) == 2 ){
					printf( "WITH GRAY " );
					c = c | 0x40;
					index++;
				}
				index += i;
				if( i < 64 ){
					c = c + (unsigned char)i;
					this->compressed.push_back( c );
					printf( "0x%02X ", c );
				}
				else{
					this->compressed.push_back( c );
					printf( "0x%02X ", c );
					i = i - 63;
					while( i ){
						if( i < 256 ){
							this->compressed.push_back( i );
							printf( "0x%02X ", i );
							break;
						}
						else{
							this->compressed.push_back( 0 );
							printf( "0x%02X ", 0 );
							i = i - 255;
						}
					}
				}
				printf( "\n" );
			}
			current_color = 3 - current_color;
		}
		else{
			//	ÉOÉåÅ[ÇÃèÍçáÇÕÅA[0][C1][C2][C3][N] ÇégÇ§
			c = ( ( this->get( index + 0 ) << 5 ) | ( this->get( index + 1 ) << 3 ) | ( this->get( index + 2 ) << 1 ) );
			current_color = this->get( index + 3 );
			c = c | ((unsigned char)current_color >> 1);
			printf( "FIXED3 %d, %d, %d [%d]\n", ( c >> 5 ) & 3, ( c >> 3 ) & 3, ( c >> 1 ) & 3, c & 1 );
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
