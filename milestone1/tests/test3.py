data: list[float] = [-2.3, 3.14, 0.9, 11, -9.1]

def insertion_sort(array: list[int]) -> None:
    for i in range(1, len(array)):
        key = array[i]
        j = i - 1
        while j >= 0 and key < array[j]:
            array[j + 1] = array[j]
            j -= 1
        array[j + 1] = key

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

def compute_max() -> float:
  max_value: float = None
  i: int = 0
  for i in range(len(data)):
    if not max_value:
      max_value = data[i]
    elif data[i] > max_value:
      max_value = data[i]
  return max_value

def main():
    data: list[int] = [-2, 45, 0, 11, -9]
    insertion_sort(data)
    print('Sorted Array in Ascending Order:')
    for num in data:
        print(num)

if __name__ == "__main__":
    main()
