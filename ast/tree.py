#!/usr/bin/python
# -*- coding: utf-8 -*-

__all__ = ['NotAnAstError', 'Tree']

import copy
from api.errors import Error

class NotAnAstError(Error):
    ''' Thrown when the "pointer" is not
    an AST, but another thing.
    '''
    def __init__(self, instance):
        self.instance = instance
        self.msg = "Object '%s' is not an Ast instance" % str(instance)

    def __str__(self):
        return self.msg



class Tree(object):
    ''' Simple tree implementation
    '''
    def __init__(self):
        self.children = []

    def inorder(self, funct, stopOn = None):
        ''' Iterates in order, calling the function with the current node.
        If stopOn is set to True or False, it will stop on true or false.
        '''
        if stopOn is None:
            for i in self.children:
                i.inorder(funct)
        else:
            for i in self.children:
                if i.inorder(funct) == stopOn:
                    return stopOn

        return funct(self)


    def preorder(self, funct, stopOn = None):
        ''' Iterates in preorder, calling the function with the current node.
            If stopOn is set to True or False, it will stop on true or false.   
        '''
        if funct(self.symbol) == stopOn and stopOn is not None:
            return stopOn

        if stopOn is None:        
            for i in self.children:
                i.preorder(funct)
        else:
            for i in self.children:
                if i.preorder(funct) == stopOn:
                    return stopOn
                    

    def postorder(self, funct, stopOn = None):
        ''' Iterates in postorder, calling the function with the current node.
        If stopOn is set to True or False, it will stop on true or false.
        '''
        if stopOn is None:
            for i in range(len(self.children) - 1, -1, -1):
                self.children[i].postorder(funct)
        else:
            for i in range(len(self.children) - 1, -1, -1):
                if self.children[i].postorder(funct) == stopOn:
                    return stopOn

        return funct(self.symbol)
        
        
    def appendChild(self, node):
        ''' Appends the given node to the current children list
        '''
        self.children.append(node)


    def prependChild(self, node):
        ''' Inserts the given node at the beginning of the children list
        '''
        self.children.insert(0, node)


    @classmethod
    def makenode(clss, symbol, *nexts):
        ''' Stores the symbol in an AST instance,
        and left and right to the given ones
        '''
        result = clss(symbol)
        for i in nexts:
            if i is None:
                continue
            if not isinstance(i, clss):
                raise NotAnAstError(i)
            result.appendChild(i)

        return result


    def __deepcopy(self, memo):
        result = Tree(self.symbol) # No need to duplicate the symbol memory
        result.next = copy.deepcopy(self.children)

        return result

