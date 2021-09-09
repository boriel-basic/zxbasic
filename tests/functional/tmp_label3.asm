;; Cannot access labels in different namespaces
push namespace test
1:
pop namespace

ld hl, 1b

