// --------------------------------------------------------------------
//	MSX Boot logo converter
// ====================================================================
//  8th/Dec./2021	t.hara
// --------------------------------------------------------------------

#include <iostream>
#include "cbitmap.hpp"
#include "compressor.hpp"

// --------------------------------------------------------------------
static void usage( const char *p_name ){

	std::cout << "Usage> " << p_name << " <input_image.bmp> <output.bin>" << std::endl;
	std::cout << "  The input_image.bmp must be an uncompressed 24bpp BMP." << std::endl;
	std::cout << "  Only the 422 x 80 in the upper left corner is valid." << std::endl;
}

// --------------------------------------------------------------------
int main( int argc, char *argv[] ){
	std::cout << "MSX LOGO Conveter" << std::endl;
	std::cout << "=====================================================" << std::endl;
	std::cout << "8th/Dec./2021  Programmed by HRA!." << std::endl;

	if( argc != 3 ){
		usage( argv[ 0 ] );
		return 1;
	}

	cbitmap bmp_file;
	try{
		bmp_file.load( argv[ 1 ] );
	}
	catch( const char *p_error ){
		std::cerr << p_error;
		return 1;
	}

	ccompressor compress;
	compress.converter( bmp_file );
	compress.run();

	try{
		compress.save( argv[ 2 ] );

		std::vector< unsigned char > decode;
		compress.decompress( decode );
	}
	catch( const char *p_error ){
		std::cerr << p_error;
		return 1;
	}

	return 0;
}
