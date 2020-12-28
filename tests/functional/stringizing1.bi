

#define x(a, b) q(a##b)
#define q(a)  #a

x(a, b)
q(5)

