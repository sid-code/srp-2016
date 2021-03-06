## Answering questions with K-parser

This is where I'll be putting the code that I write for my high school Senior
Research Project. You can also read [my blog][1].

### The K-parser
K-parser is a semantic parser found at [kparser.org][2] developed at [the lab I
work with][3].  It deconstructs sentences and displays useful information about
the relationship between entities described in a neat graph, called a Knowledge
Description Graph, or KDG.

I aim to leverage K-parser in finding the answering questions tha can be
answered with Freebase, a huge collection of facts that is freely available.
Inspiration for this project comes from [SEMPRE][4], a project at Stanford that
attempts the same thing but without K-parser, which solves some of the problems
Percy Liang mentions at the bottom of his [main paper on SEMPRE][5] (see the
section called "Error analysis").

### What I have right now

To work with K-parser, I can't keep using the web interface because that gets
tedious. So, I wrote a Nim program to send the same requests the web interface
sends to the server and parse the JSON into my own internal representation of a
KDG and then do transformations and what not.

(If you're wondering what Nim is, [here is its website][7].)

If you want to try it out for yourself, [get the nim compiler][6], make sure you
have SSL (required to use Google's APIs), and run:
```
nim c -d:ssl read917
./read917
```

Don't worry about the output of the program, it's not finished yet. All that
matters is that it compiles and runs.

As I am developing this on a Linux system, I have no idea whether it will work on
a Windows system.

### External tools used
 1. [K-parser](http://kparser.org)
 2. [Dandelion](https://dandelion.eu/)
 3. [Google's Freebase API](https://developers.google.com/freebase/) (deprecated
    but still required)

## License

All code here is released under the MIT license.

[1]: http://sidharthkulkarnisrp.blogspot.com/
[2]: http://kparser.org
[3]: http://www.fulton.asu.edu/~bioai/
[4]: http://www-nlp.stanford.edu/software/sempre/
[5]: http://cs.stanford.edu/~pliang/papers/freebase-emnlp2013.pdf
[6]: http://nim-lang.org/download.html
[7]: http://nim-lang.org/
