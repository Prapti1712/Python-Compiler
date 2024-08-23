def complex_arithmetic(a: int, b: int, c: int) -> int:
    temp:int = 0
    a = a+2
    b = b +1
    temp = a * b
    print(temp)
    c+=temp
    a //= 3
    b %= 5
    temp = a ** b
    print(temp)
    c-=temp
    a &= 7
    b |= 10
    temp= (a + b) / 2
    print(temp)
    c*=temp
    return c
def return_highest(a:int, b:int, c:int)->int:
    result:int = 0
    if a>=b and a>=c:
        result = a
    elif b>=a and b>=c:
        result = b
    else:
        result = c
    return result
def main():
    a:int = 10
    b:int = 20
    c:int = 30
    result:int = 0
    result = complex_arithmetic(a,b,c)
    print(result)
    highest:int = 0
    highest = return_highest(a,b,c)
    print(a)
    print(b)
    print(c)
    print(highest)

if __name__ == "__main__":
    main()
