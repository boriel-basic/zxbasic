#!/usr/bin/python
# -*- coding: utf-8 -*-

class Symbol(object):
	''' Symbol object to store everything related to
	a symbol.
	'''
	def __init__(self, value, token):
		self.text = value
		self.token = token # e.g. 'ID', 'number', etc...

		try:
			self.value = float(value)
		except ValueError:
			self.value = None # Not a number value
		except TypeError:
			self.value = None # Not a number value


