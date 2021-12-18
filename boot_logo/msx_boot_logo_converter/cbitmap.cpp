// --------------------------------------------------------------------
//	BMPƒtƒ@ƒCƒ‹‚ğ“Ç‚İ‚Ş
// ====================================================================
//	8th/Dec./2021	t.hara
// --------------------------------------------------------------------

#include <fstream>
#include <cstring>
#include "cbitmap.hpp"

// --------------------------------------------------------------------
#pragma pack(1)
typedef struct tagBITMAPFILEHEADER {
	uint8_t bfType0;
	uint8_t bfType1;
	uint32_t bfSize;
	uint16_t bfReserved1;
	uint16_t bfReserved2;
	uint32_t bfOffBits;
} BITMAPFILEHEADER;

typedef struct tagBITMAPINFOHEADER {
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
void cbitmap::load( std::string s_file_name ){
	std::ifstream file( s_file_name, std::ios::binary );

	if( !file ){
		throw ("Cannot open " + s_file_name).c_str();
	}

	BITMAPFILEHEADER fi;
	memset( &fi, 0, sizeof( fi ) );
	file.read( (char*)&fi, sizeof( fi ) );

	BITMAPINFOHEADER ih;
	memset( &ih, 0, sizeof( ih ) );
	file.read( (char *)&ih, sizeof( ih ) );

	if( fi.bfType0 != 'B' || fi.bfType1 != 'M' ){
		throw "It's not a BMP file.";
	}
	if( ih.biBitCount != 24 || ih.biCompression != BI_RGB ){
		throw "Unsupported format.";
	}
	file.seekg( fi.bfOffBits, std::ios_base::beg );

	this->width = ih.biWidth;
	this->height = ih.biHeight;
	this->byte_width = ( this->width * 3 + 3 ) & ~3;

	this->image.resize( this->byte_width * this->height );
	file.read( (char *)( this->image.data() ), this->image.size() );
	file.close();

}

// --------------------------------------------------------------------
void cbitmap::get_pixel( int x, int y, unsigned char &r, unsigned char &g, unsigned char &b ) const {
	int index;

	if( x < 0 || y < 0 || x >= this->width || y >= this->height ){
		return;
	}

	index = x * 3 + (this->height - y - 1) * this->byte_width;
	b = this->image[ index + 0 ];
	g = this->image[ index + 1 ];
	r = this->image[ index + 2 ];
}
