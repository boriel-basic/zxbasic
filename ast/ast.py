#!/usr/bin/python
# -*- coding: utf-8 -*-

__all__ = ['NotAnAstError', 'Ast']

import copy
from obj.errors import Error

class NotAnAstError(Error):
	''' Thrown when the "pointer" is not
	an AST, but another thing.
	'''
	def __init__(self, instance):
		self.instance = instance
		self.msg = "Object '%s' is not an Ast instance" % str(instance)

	def __str__(self):
		return self.msg



class Ast(object):
	''' Abstact syntax tree.
	'''
	def __init__(self, symbol = None):
		self.next = []
		self.symbol = symbol
		self.symbol.this = self # Stores self_pointer


	def inorder(self, funct):
		''' Iterates in order, calling the function with the current node
		'''
		for i in self.next:
			i.inorder(funct)

		funct(self.symbol)


	def preorder(self, funct):
		''' Iterates in preorder, calling the function with the current node
		'''
		funct(self.symbol)

		for i in self.next:
			i.preorder(funct)


	def postorder(self, funct):
		''' Iterates in postorder, calling the function with the current node
		'''
		for i in range(len(self.next) - 1, -1, -1):
			self.next[i].postorder(funct)

		funct(self.symbol)


	@classmethod
	def makenode(clss, symbol, *nexts):
		''' Stores the symbol in an AST instance,
		and left and right to the given ones
		'''
		result = clss(symbol)
		for i in nexts:
			if i is None: continue
			if not isinstance(i, clss):	raise NotAnAstError(i)
			result.next.append(i)

		return result


	def __deepcopy(self, memo):
		result = Ast(self.symbol) # No need to duplicate the symbol memory
		result.next = copy.deepcopy(self.next)

		return result

