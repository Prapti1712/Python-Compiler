data: list[float] = [-2.5, 45.0, 0, 11.1, -9.3]

num = 29
flag = False

if num == 1:
    print(num, "is not a prime number")
elif num > 1:
    for i in range(2, num):
        if (num % i) == 0:
            flag = True
            break
    if flag:
        print(num, "is not a prime number")
    else:
        print(num, "is a prime number")

def generate_fibonacci_series(limit: int) -> list[int]:
    fibonacci_series = [0, 1]
    while True:
        next_fibonacci = fibonacci_series[-1] + fibonacci_series[-2]
        if next_fibonacci > limit:
            break
        fibonacci_series.append(next_fibonacci)
    return fibonacci_series

def compute_avg() -> float:
  avg_value: float = None
  sum: int = 0
  i: int = 0
  for i in range(len(data)):
    sum += data[i]
  return sum / len(data)

def main():
    print('Ascending Order:')
    for num in data:
        print(num)

if __name__ == "__main__":
    main()
