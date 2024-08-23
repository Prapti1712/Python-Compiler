class dog():
    def __init__(self,a1:int, b1:int, c1:int):
        self.aa:int = a1
        self.bb:int = b1
        self.cc:int = c1
    def add(self):
        c:int = self.aa + self.bb + self.cc
        print(c)
class animal(dog):
    def __init__(self,a1:int,b1:int,c1:int):
        self.a:int=a1
        self.b:int=b1
        self.c:int=c1
        dog.__init__(self,a1,b1,c1)
    def add_animal(self):
        d:int=self.a+self.b+self.c+self.cc
        print(d)
def main():
    a:int = 2
    b:int = 5
    c:int = 7
    you: dog = dog(a,b,c)
    you.add()
    d: animal=animal(a,b,c)
    d.add_animal()
    return

