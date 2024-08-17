class MyClass:
    def __init__(self, name: str):
        self.__name: str = name
class CLASSNAME:
    def get_name(self) -> str:
        return self.__name
class CLASSTEXT:    
    def set_name(self, new_name: str) -> None:
        self.__name = new_name

def binarySearch(array: list[int], x: int, low: int, high: int) -> int:
  while low <= high:
    mid: int = low + (high - low) // 2
    if array[mid] == x:
      return mid
    elif array[mid] < x:
      low = mid + 1
    else:
      high = mid - 1
  return -1


def main():
  array: list[int] = [3, 4, 5, 6, 7, 8, 9]
  result: int = binarySearch(array, 4, 0, len(array) - 1)
  if result != -1:
    print("Element is present at index:")
    print(result)
  else:
    print("Element is not present")

def main() -> None:
    obj: MyClass = MyClass("Example")
    print( obj.get_name())
    obj.set_name("NewName")
    print(obj.get_name())

if __name__ == "__main__":
    main()
