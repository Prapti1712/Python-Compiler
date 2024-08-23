def main():
   i:int = 0
   j:int = 0
   k:int = 0
   c:int = 301
   d:int = 401
   print("This testcase is for testing breaks and strings")
   for i in range(1, 6):
      print("Outer loop iteration")
      for j in range(1, 4):
         print("    Inner loop iteration")
         for k in range(1, 5):
               print("        Nested loop iteration")
               if k % 2 == 0:
                  print("            Skipping even value")
                  break
               if k == 3:
                  print("            Breaking out of nested loop")
                  break
         if j == 2:
               print("    Skipping remaining iterations of inner loop")
               break
         if i == 3:
               print("Breaking out of outer loop")
               break 
if __name__=="__main__":
   main()
