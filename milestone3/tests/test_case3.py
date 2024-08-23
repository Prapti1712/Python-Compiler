def while_loop(start: int, end: int) -> int:
    result:int = 0
    while start <= end:
        if start % 2 == 0:
            result = result+ start ** 2
        else:
            result = result+ start ** 3
        start += 1
    return result

def main():
    arr:list[int] = [0,1,2,3,4,5]
    size:int = len(arr)
    print(size)
    print(arr[0])
    print(arr[1])
    print(arr[2])
    print(arr[3])
    print(arr[4])
    a:int = arr[4] + arr[3]
    print(a)
    start_value:int = arr[0]
    end_value:int = arr[5]
    result:int = 0
    result = while_loop(start_value, end_value)
    print(result)
