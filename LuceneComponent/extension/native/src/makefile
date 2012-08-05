all: extension

target=LuceneComponent.dll

commonInclude=./../../../../Common/include/
commonLib=./../../../../Common/lib/

src=Extension.cpp

lib=-lFlashRuntimeExtensions -llibclucene-core -L$(commonLib)

inc=-I$(commonInclude) -I$(CLUCENE)\src\core -I$(CLUCENE)\src\shared

flags=-Wall -shared -static-libgcc -static-libstdc++

extension: $(src) Extension.h
	g++ $(flags) $(src) $(lib) $(inc) -o ./../bin/$(target)

