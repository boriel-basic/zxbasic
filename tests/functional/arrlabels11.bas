REM tests a local array with @label references

SUB test
    DIM a(1 TO 3) as UInteger => {@a, @a + 1, 3}
END SUB

