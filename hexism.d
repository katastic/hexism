

//FIXME:
// "IFF chunks are always padded to an even number of bytes. The possible padding byte is not included in chunk_size."
/*
version(DigitalMars)
	{
	pragma(lib, "dallegro5_dmd");
	}
version(LDC)
	{
	pragma(lib, "dallegro5_ldc");
	}

version(ALLEGRO_NO_PRAGMA_LIB)
	{}else{
	pragma(lib, "allegro");
	pragma(lib, "allegro_primitives");
	pragma(lib, "allegro_image");
	pragma(lib, "allegro_font");
	pragma(lib, "allegro_ttf");
	pragma(lib, "allegro_color");
	}

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;
*/
import std.file;

import std.compiler;
import std.stdio;
import std.array;
import std.conv;
import std.string;
import std.format; 
import std.algorithm; 

import std.getopt;


enum DMODE
	{
	DEC = 0,
	HEX,
	FLOAT,
	FLOAT1 //only one digit ala 0-9
	}
	
//see https://misc.flogisoft.com/bash/tip_colors_and_formatting#foreground_text
enum ASCII
	{
	DEFAULT = "\033[0m",  // \033 = \e in bash
	DIM = "\033[2m", 
	RED = "\033[2;31m",    //add 1;31 for bold   31 or 0;31 for normal i think. 2=dim
	LIGHT_GREY = "\033[37m",
	DARK_GREY = "\033[90m"
	}
	

enum HIGHLIGHT_MODE
	{
	RAW=0,   	// PRINT THEM TO STDIO and let the cursors fall where they may! (for piping)
	DOT, 		// all non-printables become dots
	COLOR, 	// colorized letters red N for newline. red T for tab. Configure the color??? or bold?
	UNICODE, // tab = u21b9
	TRUECOLOR 		// If terminal supports it, use RGB values to show HEX PRINTESS directly in the console!  0x10 = 16 = RGB(16,16,16).
	}
	
string color(string data, ASCII col)
	{
	return col ~ data ~ ASCII.DEFAULT; 
	}

class file_t
	{
	File file;
	char[] c;
	char[] c_view;
	 
	void save(string path){}

	HIGHLIGHT_MODE hmode = HIGHLIGHT_MODE.COLOR;
	DMODE mode = DMODE.HEX; // <------ MODE SELECTOR


//http://muratnkonar.com/aiff/aboutiff.html
//"Note that the ULONG byte count is stored in Big Endian order (ie, the Most Significant Byte is first, and the Least Significant Byte is last). This is how the Motorola 680x0 stores long values in memory (ie, the opposite order of Intel 80x86). IFF files use Big Endian order for all 16-bit (ie, SHORT) and 32-bit (ie, LONG) values."

	void find_iff(string path)
		{
		void[] bytes = read(path);
//		void[] bytes = read("tanktics.exe");
		c = cast(char[])bytes;
	/*	
		bool found_start=false;
		
		writeln("Attempting to run LINEAR PASS");
		writeln("================================================");
		uint j = 0; 
		while(j < c.length - 4) //-4? Not exactly safest assumption...
			{
			if(c[j..j+4] == "FORM")
				{
				found_start = true;
				char[] chunk_name = c[j..j+4]; 
				char[] cl = c[j+4..j+4+4]; // CHNK....
				uint chunk_length = 
					cl[3]*1  + 		//CONFIRM BYTE ORDERING?!
					cl[2]*256 + 		// 1, 2, 3, 4?  4, 3, 2, 1?
					cl[1]*256*256 + 	//or  [2, 1], [4, 3]
					cl[0]*256*256*256;

				writef("%8s @ %d [len=%d][next=%d] - ", chunk_name, j, chunk_length, j+chunk_length);
				writefln("%02x %02x %02x %02x", cl[0], cl[1], cl[2], cl[3]);				
//				if(chunk_length == 0){writefln("\n * LENGTH ERROR");break;}
				writefln("adding %d + %d = %d", j, chunk_length, j + chunk_length);
				
				j = j + chunk_length - 16; // -16?!?!
				continue; //needs to be 924500
				}
				
				if(found_start)
					{
					char[] chunk_name = c[j..j+4]; 
					char[] cl = c[j+4..j+4+4]; // CHNK....
					uint chunk_length = 
						cl[3]*1  + 		//CONFIRM BYTE ORDERING?!
						cl[2]*256 + 		// 1, 2, 3, 4?  4, 3, 2, 1?
						cl[1]*256*256 + 	//or  [2, 1], [4, 3]
						cl[0]*256*256*256;
					writef("%8s @ %d [len=%d][next=%d] - ", chunk_name, j, chunk_length, j+chunk_length);
					writefln("%02x %02x %02x %02x", cl[0], cl[1], cl[2], cl[3]);				
					j+= chunk_length - 16;
//					break;
					}
				
				j++;
			}

//		if(c.length > 0)return;

//0001b2d9 BODY....

		writeln("Attempting to find FOLLOW CHUNKS");
		writeln("================================================");
		bool found_FORM = false;
		for(int i= 0; i < c.length - 4; i++) //-4? Not exactly safest assumption...
			{
//			if(!found_FORM)
			if(true) // what about MULTIOPLE FORMS?
				{
				if(c[i..i+4] == "FORM")
					{
					found_FORM = true;
					writef("Found\n    FORM @ %d", i);
					
					char[] cl = c[i+4..i+4+4]; // FORM.... SIZE
					writefln(" - %02x %02x %02x %02x", cl[0], cl[1], cl[2], cl[3]);				
					}
//				continue;
				}
			if(c[i..i+4] == "BODY")
				{
//				writefln("BODY TIME");
				char[] chunk_name = c[i..i+4]; 
				char[] cl = c[i+4..i+4+4]; // CHNK....
				uint chunk_length = 
					cl[3]*1  + 		//CONFIRM BYTE ORDERING?!
					cl[2]*256 + 		// 1, 2, 3, 4?  4, 3, 2, 1?
					cl[1]*256*256 + 	//or  [2, 1], [4, 3]
					cl[0]*256*256*256; 
				
				int OFFSET=0;
					
				writef("%8s @ %d [len=%d][next=%d] - ", chunk_name, i, chunk_length, i+chunk_length+OFFSET);
				writefln("%02x %02x %02x %02x", cl[0], cl[1], cl[2], cl[3]);				
				if(chunk_length == 0){writefln("\n * LENGTH ERROR");break;}
				i += chunk_length+OFFSET;
				
				continue;
				}
			
			
			// THIS CAN'T BE RIGHT. +7?!

			//looks like there's only
			// CDAT DIAL   --- s=32 (CDATIVER.32.TEXT.24."can't find tanktics CD"DIAL.36.TEXT.28.    )   
			// CDAT IVER   --- s=12	
			// CDAT PANL   --- size=307224 !!
			
			if(true) //if it's a EIGHT DIGIT one!!! FIXME
				{
				char[] chunk_name = c[i+7..i+7+8]; //+8 becuase "FORM....[then chunk name]"
				char[] cl = c[i+7+4+4..i+7+8+4]; // CHNK....
				uint chunk_length = 
					cl[3]*1  + 		//CONFIRM BYTE ORDERING?!
					cl[2]*256 + 		// 1, 2, 3, 4?  4, 3, 2, 1?
					cl[1]*256*256 + 	//or  [2, 1], [4, 3]
					cl[0]*256*256*256; 
							// Duh. 256! Because each 8-bit char is 256!!!
				
				// 00 03 74 fc
				//  should be 226,556 ... wait does htat make sense?
				// https://www.binaryhexconverter.com/hex-to-decimal-converter
				
				// 227460 (FROM START OF FILE)
				
				int OFFSET=-46;
					
				writef("%8s @ %d [len=%d][next=%d] - ", chunk_name, i, chunk_length, i+chunk_length+OFFSET);
				writefln("%02x %02x %02x %02x", cl[0], cl[1], cl[2], cl[3]);				
				if(chunk_length == 0){writefln("\n * LENGTH ERROR");break;}
				i += chunk_length+OFFSET;
				}
				
			
			}
*/
//		if(c.length > 0)return; //fuck you.

		struct pair_t
			{
			int address;
			int end_address;
			int length; //we're using -1 for bad entries right now.
			string name;

			int indent;
			ulong debug_index;
			bool skip_special_chunk;
			pair_t[] sub_pieces;
			}

		pair_t[] pieces;
		pieces.reserve(2655+1);

		writeln("Attempting to find IFF signatures");
		writeln("================================================");
		int i = 0;
		while(i < c.length - 4)
			{
//			writefln("%s ", c[i..i+4]);

			if( c[i..i+4] == "CDAT") // CHUNK CLASS / ID. NO SIZE AFTER THIS. Immediately goes into chunk type.   CDATIVER = CDAT IVER xxxx    where xxxx = size
				{
//				writefln(" ------- CDAT found @ ");
				pair_t t;
				t.address = i;
				t.name = "CDAT";
				t.length = 0;
				t.end_address = 0;
				t.skip_special_chunk = true;
				
				//pieces ~= t;   //TEMP. SKIP THIS FOR NOW.8
				
				// FOUND A MATCH, so let's move forward CDAT = +4
				i += 4; //note 4, no chunk length data
				continue;

				}

			string chunkname = to!string(c[i..i+4]); // speed this up a bit. I think.
			if(
				// likewise, merged down:				
				chunkname == "FORM" || 
				chunkname == "DATA" || 
		
				//these WERE CDATSTON CDATIVER, CDATPANL. But then PANL could also be separate!
				chunkname == "IVER" || 
				chunkname == "STON" || 
				chunkname == "PANL" || 
				chunkname == "TILE" || 
				chunkname == "DIAL" ||
	
				chunkname == "BODY" || //why did BODY need a separate? Doesn't now. So moved here.
	
				// the rest (MAY BE DUPLICATES!) but the OR'ing won't break it.
				chunkname == "BHGR" || //7
				chunkname == "BMRB" || 
				chunkname == "BMRG" ||
				chunkname == "BMRS" ||
				chunkname == "BRDN" || //ditto
 				chunkname == "BRDP" || // Shows up right before DATA.
				chunkname == "BUTA" ||
				chunkname == "BUTT" ||
	//			chunkname == "CDEF" || //8
				chunkname == "CHBG" || //7
				chunkname == "CHGR" || //9
				chunkname == "CPAL" || // 3 - palettes?! Menu, game, +???
				chunkname == "DATY" || //"DATA" is separate above. 289 DATA's.   DATY might not be real.
	//			chunkname == "DEFG" || // DEFINITINO?
				chunkname == "DTXT" || 
				chunkname == "DIAC" || // CDATDIAL "dialog box test" then DIAC as in maybe dialog metadata.  
				chunkname == "DINP" || // "Enter Name: " DINP TEXT "reciver detected"... followed by HUGE AMOUNTS of ingame text / chat messages for levels.
				chunkname == "FEND" || // 138?!
	//			chunkname == "GEED" || // 95?! Removed. It has HUGE lengths. Not real.
		//		chunkname == "HDAT" || // HDAT why missing from FOURCAPS critera??? . REMOVED. 1090519040 length lul.
				chunkname == "HLTK" ||
				chunkname == "HLT " ||
				chunkname == "LOSE" || //lose
				chunkname == "MEDI" || //medieval
				chunkname == "MESG" || //message
				chunkname == "MICO" ||
				chunkname == "MODN" ||	//modern
				chunkname == "PANL" ||
				chunkname == "PHBG" ||
				chunkname == "PHGR" ||
				chunkname == "RHBG" ||
				chunkname == "TABG" ||
				chunkname == "TBGC" ||
				chunkname == "TWND" ||
				chunkname == "TILE" || // tile!
				chunkname == "TEXT" || // Text! 4
//				chunkname == "UTST" || // ?? >79   .UTST.
				chunkname == "WINS"   //win  as in (WIN) (S)CREEN?
				)
				{
				char[] cl = c[i+4..i+8];
				uint chunk_length = 
					cl[3]*1 + 		//CONFIRM BYTE ORDERING?!qq
					cl[2]*256 + 		// 1, 2, 3, 4?  4, 3, 2, 1?
					cl[1]*256*256 + 		//or  [2, 1], [4, 3]
					cl[0]*256*256*256;
					
				pair_t t;
				t.address = i;
				t.name = chunkname;	
				t.length = chunk_length;
				t.end_address = i + chunk_length + 8 - 1; // add offset?    
				
				if(chunk_length > 26_587_019)
					{
					// these aren't REAL! C:\DATA\ is tagged!
					// STON is in a bunch of random letters.
					// TILE, MEDI, and BODY are both ITEM NAMES surrounded by underscores and more letters
					// LOSE - "GENERIC_BONUS_LOSE_EXPERIENCE"
					// All of these have HUGELY WRONG sizes! So let's just ignore them!

					// DEBUG: show hex values of data. not needed.					
//					t.name = format("%s - [%x]", chunkname, chunk_length);

					t.length = -1;
					t.end_address = -1;
					t.skip_special_chunk = true;
					t.debug_index = i;
				//	pieces ~= t; remove them from list by simply not adding them. left for debug.
					}else{
					t.skip_special_chunk = false;
					t.debug_index = pieces.length;
					pieces ~= t;
					}
				// FOUND A MATCH, so let's move forward BODY____ = +8
				i += 8;
				continue;
				}
			
			// NO MATCHES, so increment +1.
			i++;
			}

		writeln();
		writefln("RESULTS:");
		writefln("====================================================");
		foreach(idx, s; pieces)
			{
//			writefln("%4d - %s S=%d E=%d L=%d", idx, s.name, s.address, s.end_address, s.length);
			}
		
		writeln();
		writefln("Now let's (attempt to) build a tree.");
		writefln("====================================================");
		
		pair_t root2;
		root2				= pieces[0];
		root2.indent 		= 0;
		root2.sub_pieces 	= pieces[1..$];

		int DEBUG_COUNT=0;
		void recursive(ref pair_t root, int master_indent)
			{
			if(root.address > root.end_address)
				{
				writefln("[root node] i=%d %s %s (a:%d ea:%d L:%d) [RL=%d] [INDX=%d] ????????????????", 
					master_indent, 
					"-".replicate(master_indent), 
					root.name, 
					root.address, 
					root.end_address, 
					root.length, 
					root.sub_pieces.length, 
					root.debug_index);
				}else{
				writefln("[root node] i=%d %s %s (a:%d ea:%d L:%d) [RL=%d] [INDX=%d]", 
					master_indent, 
					"-".replicate(master_indent), 
					root.name, 
					root.address, 
					root.end_address, 
					root.length, 
					root.sub_pieces.length, 
					root.debug_index);
				}

			DEBUG_COUNT++;
			if(DEBUG_COUNT > 10){writefln("Ten levels is too deep!"); return;}

			ulong start_of_index = 0; 
			ulong end_of_index = 0; 
			writefln("RUN LOOP from %d to %d", root.sub_pieces[0].debug_index, root.sub_pieces.length);
//			foreach(idx, p; root.sub_pieces) 
			for(int idx = 0; idx < root.sub_pieces.length; idx++)
				{
				pair_t p = root.sub_pieces[idx];
				// but with exceptions below. BECAUSE WE MUTATE BABY!!!!
				
				if(p.address <= root.end_address)
					{
//					root.sub_pieces ~= p; // don't MODIFY what we're iterating. Need second RANGE or something. 
					writefln("[inside] i=%d indent=%d %s %s (a:%d ea:%d L:%d) [RL=%d] [INDX=%d]", i,  master_indent+1, "-".replicate(master_indent+1), p.name, p.address, p.end_address, p.length, root.sub_pieces.length, p.debug_index);
					}
					
				// we're done. I guess. split and return?
				// or, run the pattern recognition on the sub-pattern?
				if(p.address > root.end_address)
					{
					start_of_index = end_of_index+1; //the last one that was run. (+1 because it's AFTER that are inside.)
					end_of_index = idx; //-1 

					ulong u = to!ulong(idx);
					if(
						u < root.sub_pieces.length && //out-of-bounds check
						root.sub_pieces[u+1].address <= root.end_address
						)
						{
						writefln("[next sub_piece is inside, continue!] - i=%d - %s (a:%d ea:%d L:%d) [RL=%d] [INDX=%d]", master_indent, p.name, p.address, p.end_address, p.length, root.sub_pieces.length, p.debug_index);
						continue;
						}
					
					writefln("Sub-section runs from [%d] to [%d]", start_of_index, end_of_index);
					writefln("--------Exceeded Address Length-----------");
					writefln("--------ROOT UPDATE OCCURED-----------");
	
					root 			= pieces[end_of_index];
					root.sub_pieces = pieces[start_of_index..end_of_index+1]; 
					
					foreach(t; root.sub_pieces)
						{
//						writefln("[sub_pieces] i=%d %s %s (a:%d ea:%d L:%d) [L=%d] [root.INDX=%d][t.INDX=%d] [LE.EA=%d]", master_indent, "-".replicate(master_indent), t.name, t.address, t.end_address, t.length, root.sub_pieces.length, root.debug_index,t.debug_index, last_element.end_address);
						}
// 					recursive(root, master_indent+1);
					writefln("NEW ROOT - i=%d - %s", root.indent, root.name);

					writefln("[root node] i=%d %s %s (a:%d ea:%d L:%d) [RL=%d] [INDX=%d]", master_indent, "-".replicate(master_indent), root.name, root.address, root.end_address, root.length, root.sub_pieces.length, root.debug_index);

					//indent--; //???
					}
				
//				idx = 0;
				}
			
			}
		
		recursive(root2, 0);
		
		
		}

	void load3(string path)
		{
//		file = File(path, "r");
		void[] bytes = read("tankdata.bin");
//		void[] bytes = read("tanktics.exe");
		 c = cast(char[])bytes;
		 c_view = c.dup;
		//writeln(c.length);

		// NOT QUITE FINISHED HERE. We're actually changing the data. What if we kept TWO sets? What we DRAW vs what it IS? Not sure.
		for(int i = 0; i < c_view.length; i++)
			{
			if(cast(int)(c_view[i]) < 32)c_view[i]='.'; //all non-printables become a dot.
			//https://web.itu.edu.tr/sgunduz/courses/mikroisl/ascii.html

			if(cast(int)(c_view[i]) > 127)c_view[i]='*'; // UTF-8 special characters start after 127. So you'll never see extended ASCII map up there, IIRC. Or is there a very specific "above 127" that counts as "Diacritics"? Or is Diacritics JUST "e" with dot/notch/etc? And not ANY unicode?

			// Maybe they use some or a RANGE and KEEP other "eASCII" characters?
			// - https://www.utf8-chartable.de/unicode-utf8-table.pl
			// 7F (127) through C2 9F [control characters]
			// Looks like they kept lots of (new) standard ones like Euro and fraction ¼.
			// 
			}

	//https://forum.dlang.org/post/glxdguxzcmpqirxgimkc@forum.dlang.org
	
//	c = readText!(char[])(path);

	display();
	}

	void display()
		{
		writefln("File length: %d (0x%x)", c.length, c.length);
		//writefln("-------------------------------------------------");
		
		int START_OFFSET=0; //how about negative offsets?
		// + = seek forward, moving everything left and up.
		// - = seek backwards = adding some padding to the beginning.
		int ACTUAL_OFFSET = START_OFFSET; //note we "fix" one but keep the other so we remember we changed it by how much.		
		//FIXME: <------Use BETTER NAMES!!!!!!!!!!!!!!!!!!!!!!!!!
		// offsets sound way too similar. ALSO c and c_view really need something
		// to prevent errors in access.
		if(START_OFFSET<0)
			{
			c = " ".replicate(-START_OFFSET) ~ c; //padd with spaces
			ACTUAL_OFFSET = 0;
			}
		
		void write_position(int value)
			{
			writef("%08x  ", value);
			}
		
		int COLUMNS = 16; //haven't tested changing from 16!
		int GROUP_BY = 8;
		
		write_position(0); //note: two places.
		for(int i=ACTUAL_OFFSET; i < c.length; i++)
			{
			
			if(START_OFFSET+i < ACTUAL_OFFSET)
				{
					// do what? (not sure if logic is right too)
					// do we COLOR the pre-blocks? or simply replace those numbers with SPACES
					// in the hex version and something??? (color) in the text version?
				writef("-- "); 
				}else{
	//			writefln("i=%d", i); //debug
				if(mode == DMODE.HEX)
					writef("%02x ", c[i]); 
				if(mode == DMODE.DEC)
					writef("%3d ", c[i]); 
				if(mode == DMODE.FLOAT)
					writef("%3.0f ", to!(float)(c[i])/256.0*100); 
				if(mode == DMODE.FLOAT1)
					writef("%1.0f ", to!(float)(c[i])/256.0*10); 
				}

				if( (i+ 1 - ACTUAL_OFFSET) % COLUMNS == GROUP_BY) //NOT TESTED ALL VARIABLES YET
					{
					write(" ");
					}

				if( (i + 1 - ACTUAL_OFFSET) % COLUMNS == 0)
					{
					if(hmode == HIGHLIGHT_MODE.UNICODE)
						{
						char []t = cast(char[])(c_view[i-15 .. i+1])
							.replace("\n","\u21B5")
							.replace("\t","\u21B9");
							writefln("- [%s]", t);
						}
					if(hmode == HIGHLIGHT_MODE.COLOR)
						{
						char []t = cast(char[])(c_view[i-15 .. i+1])
							.replace("\n",color("N", ASCII.DIM))
							.replace("\t",color("T", ASCII.DIM));
						writefln(" |%s| ", t);
						}
					write_position(i+1); //note: two places
					}
		}
		writeln();
//		writefln("-------------------------------------------------");
	
		}

	
	void load2(string path)
		{
		file = File(path, "r");
		try{
		while(true)
			{
			writefln("-----------");
			auto buf = file.rawRead(new char[32]);
	
			writefln("[%s]",buf);
			if(buf.length == 0)break; // this won't work for blank lines before EOF!! ... wait, or will it?
	
			foreach(c; buf)
				{
//				writef("%d -", c);
				}
			writeln();
			writeln();
			}
		}catch(Exception e){
		//don't give a fuck
		writefln("------------------------EXCEPTION----------------------");
		}
		
		
		file.close();

		}
	
	
	void load(string path)
		{
		file = File(path, "r");
			{
			auto range = file.byLine(); 

//			foreach(l; range)
				{
//				write(l);
				}

			int i = 0;//fuckyou
			foreach(char [] line; range)
				{
				if(line.length > 0)
					{
					writefln("[%d] %s", i, line);
					foreach(c; line)
						{
						writef("%3x", c);
						}
					writeln();
					writeln();
					}else{
					writefln("%d", i);
					}
				i++;
				}
			}
	
		file.close();
		}


	void dump_to_stdio() //how do we access auto range?!?!
		{
		
		}

	
	}

int main(string[] args)
	{
	file_t file = new file_t;
//	file.load3("tanktics.exe"); //test.ini

	if(args.length == 1) file.find_iff("tankdata.bin");

	if(args.length == 2)
		{
		file.find_iff(args[1]);
		}
	return 0;
	}
