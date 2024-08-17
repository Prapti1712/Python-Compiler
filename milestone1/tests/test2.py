class ShiftReduceParser:
  def __init__(self, name_: str):
    self.srname: str = name_
class LR0Parser(ShiftReduceParser):
   def __init__(self, myname_: str, parentname_: str):
    self.lr0name: str = myname_
    ShiftReduceParser.__init__(self, parentname_)
def bubbleSort(array: list[int]) -> None:
  i: int = 0
  for i in range(len(array)):
    swapped: bool = False
    for j in range(0, len(array) - i - 1):
      if array[j] > array[j + 1]:
        temp: int = array[j]
        array[j] = array[j + 1]
        array[j + 1] = temp
        swapped = True
    if not swapped:
      break
def merge_sort(arr: list[int]) -> int:
    if len(arr) <= 1:
        return arr
    mid:int = len(arr) // 2
    left_half:int = merge_sort(arr[:mid])
    right_half:int = merge_sort(arr[mid:])
    a: int = merge(left_half, right_half)
    return a
def merge(left: list[int], right: list[int]) -> int:
    merged: int
    i:int = 0
    j:int = 0
    while i < len(left) and j < len(right):
        if left[i] < right[j]:
            merged.append(i)
            i += 1
        else:
            merged.append(j)
            j += 1
    while i < len(left):
        merged.append(i)
        i += 1
    while j < len(right):
        merged.append(i)
        i += 1
    return merged

def main() -> None:
    arr = [12, 11, 13, 5, 6, 7]
    print(arr)
    sorted_arr = merge_sort(arr)
    print(sorted_arr)

if __name__ == "__main__":
    main()
