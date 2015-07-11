#!/usr/bin/python
# -*- coding: utf-8 -*-

# -------------------------------------------------------------------------------
# Copyleft (K) 2008 by Jose M. Rodriguez de la Rosa
#
# Simple ASCII to BASIC tokenizer
#
# Implements a simple (really simple) ZX Spectrum BASIC tokenizer
# This will convert a simple ASCII text to a ZX spectrum BASIC bytes program
# -------------------------------------------------------------------------------

from api import fp
import outfmt.tzx as tzx

ENTER = 0x0D


TOKENS = {
    'LOAD': 239,
    'POKE': 244,
    'PRINT': 245,
    'RUN': 247,
    'PEEK': 190,
    'USR': 192,
    'LINE': 202,
    'CODE': 175,
    'AT': 172,
    'RANDOMIZE': 249,
    'CLS': 251,
    'CLEAR': 253,
    'PAUSE': 242,
    'LET': 231,
    'INPUT': 238,    
    'READ': 227,
    'DATA': 228,
    'RESTORE': 229,
    'NEW': 230,
    'OUT': 223,
    'BEEP': 215,
    'INK': 217,
    'PAPER': 218,
    'BORDER': 231,
    'REM': 234,
    'FOR': 235,
    'TO': 204,
    'NEXT': 243,
    'RETURN': 254,
    'GOTO': 236,
    'GO SUB': 237,
    }


class Basic(object):
    ''' Class for a simple BASIC tokenizer
    '''
    def __init__(self):
        self.bytes = [] # Array of bytes containing a ZX Spectrum BASIC program
        self.current_line = 0 # Current basic_line


    def line_number(self, number):
        ''' Returns the bytes for a line number.
        This is BIG ENDIAN for the ZX Basic
        '''
        numberH = (number & 0xFF00) >> 8
        numberL = number & 0xFF

        return [numberH, numberL]


    def numberLH(self, number):
        ''' Returns the bytes for 16 bits number.
        This is LITTLE ENDIAN for the ZX Basic
        '''
        numberH = (number & 0xFF00) >> 8
        numberL = number & 0xFF

        return [numberL, numberH]


    def number(self, number):
        ''' Returns a floating point (or integer) number for a BASIC
        program. That is: It's ASCII representation followed by 5 bytes 
        in floating point or integer format (if number in (-65535 + 65535)
        '''
        s = [ord(x) for x in str(number)] + [14] # Bytes of string representation in bytes

        if number == int(number) and abs(number) < 65536: # integer form?
            sign = 0xFF if number < 0 else 0
            b = [0, sign] + self.numberLH(number) + [0]
        else: # Float form
            (C, ED, LH) = fp.immediate_float(number)
            C = C[:2] # Remove 'h'
            ED = ED[:4] # Remove 'h'
            LH = LH[:4] # Remove 'h'

            b = [int(C, 16)] # Convert to BASE 10
            b += [int(ED[:2], 16), int(ED[2:], 16)]
            b += [int(LH[:2], 16), int(LH[2:], 16)]

        return s + b


    def token(self, string):
        ''' Return the token for the given word
        '''
        string = string.upper()

        return [TOKENS[string]]

    
    def literal(self, string):
        ''' Return the current string "as is"
        in bytes
        '''
        return [ord(x) for x in string]


    def parse_sentence(self, string):
        ''' Parses the given sentence. BASIC commands must be
        types UPPERCASE and as SEEN in ZX BASIC. e.g. GO SUB for gosub, etc...
        '''

        result = []

        def shift(string):
            ''' Returns first word of a string, and remaining
            '''
            string = string.strip() # Remove spaces and tabs

            if string == '':    # Avoid empty strings
                return ('', '')

            i = string.find(' ')
            if i == -1:
                command = string
                string = ''
            else:
                command = string[:i]
                string = string[i:]

            return (command, string)

        command, string = shift(string)
        while command != '':
            result += self.token(command)    

    
    def sentence_bytes(self, sentence):
        ''' Return bytes of a sentence.
        This is a very simple parser. Sentence is a list of strings and numbers.
        1st element of sentence MUST match a token.
        '''
        result = [TOKENS[sentence[0]]]

        for i in sentence[1:]: # Remaining bytes
            if isinstance(i, str):
                result.extend(self.literal(i))
            elif isinstance(i, float) or isinstance(i, int): # A number?
                result.extend(self.number(i))
            else:
                result.extend(i) # Must be another thing

        return result



    def line(self, sentences, line_number = None):
        ''' Return the bytes for a basic line.
        If no linenumber is given, current one + 10 will be used
        Senteces if a list of senteces
        '''
        if line_number is None:
            line_number = self.current_line + 10
        self.current_line = line_number

        sep = []
        result = []
        for sentence in sentences:
            result.extend(sep)
            result.extend(self.sentence_bytes(sentence))
            sep = [ord(':')]

        result.extend([ENTER])
        result = self.line_number(line_number) + \
            self.numberLH(len(result)) + result

        return result
            
    
    def add_line(self, sentences, line_number = None):    
        ''' Add current line to the output.
        See self.line() for more info
        '''
        self.bytes += self.line(sentences, line_number)
        
            
            

if __name__ == '__main__':
    # Only as a test if invoked from command line
    a = Basic()
    a.add_line([['CLEAR', 31999]])
    a.add_line([['POKE', 23610, ',', 255]])
    a.add_line([['LOAD', '""', a.token('CODE')]])
    a.add_line([['RANDOMIZE', a.token('USR'), 32000]])

    t = tzx.TZX()
    t.save_program('test.tzx', a.bytes, line = 1)
    t.dump('tzxtest.tzx')

