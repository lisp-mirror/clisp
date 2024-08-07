;; -*- Lisp -*- vim:filetype=lisp

(setf my-string "path-tst-test-pathname.abc"
      my-symbol 'path-tst-test-pathname.abc)
path-tst-test-pathname.abc

;; PATHNAME: argument type: pathname,string,symbol,stream
;;           result: pathname

(SETF PATHSTRING (PATHNAME MY-STRING))
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE "DISK00$ABT43"
            DIRECTORY "XCL.MAIN" SYSTEM::NAME "PATH-TST-TEST-PATHNAME"
            TYPE "ABC" SYSTEM::VERSION NIL)
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
            :NAME "path-tst-test-pathname" :TYPE "abc" :VERSION NIL)

(SETF PATHSYMBOL (PATHNAME my-symbol))
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE "DISK00$ABT43"
            DIRECTORY "XCL.MAIN" SYSTEM::NAME
            "PATH-TST-TEST-PATHNAME" TYPE "ABC" SYSTEM::VERSION NIL)
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
            :NAME "path-tst-test-pathname" :TYPE "abc" :VERSION NIL)

(SETF PATHPATH (PATHNAME PATHSYMBOL))
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE "DISK00$ABT43"
            DIRECTORY "XCL.MAIN" SYSTEM::NAME "PATH-TST-TEST-PATHNAME"
            TYPE "ABC" SYSTEM::VERSION NIL)
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
            :NAME "path-tst-test-pathname" :TYPE "abc" :VERSION NIL)

(progn
  (SETF MY-STREAM (OPEN MY-STRING :DIRECTION :OUTPUT
                        #+(or CMU SBCL) :IF-EXISTS #+(or CMU SBCL) :SUPERSEDE))
  nil)
nil

;(SETF PATHSTREAM (PATHNAME MY-STREAM))
;"test-pathname.lsp"

(MAPCAR (FUNCTION PATHNAMEP)
        (LIST PATHSTRING PATHSYMBOL PATHPATH ;PATHSTREAM
))
(T T T ;T
)


;; function truename returns filename for pathname or stream
;
;(MAPCAR (FUNCTION TRUENAME) (LIST PATHSTRING PATHSYMBOL PATHPATH MY-STREAM
;                                                               ;PATHSTREAM
;                                                                 ))
;  ERROR

(PARSE-NAMESTRING "")
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
            :NAME NIL :TYPE NIL :VERSION NIL)
#-CLISP UNKNOWN

(PARSE-NAMESTRING "./")
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY (:RELATIVE)
            :NAME NIL :TYPE NIL :VERSION NIL)
#-CLISP UNKNOWN

(NAMESTRING #P"./")
#+WIN32 ".\\"
#+UNIX "./"
#-(OR WIN32 UNIX) UNKNOWN

(PARSE-NAMESTRING MY-STRING)
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE "DISK00$ABT43"
            DIRECTORY "XCL.MAIN" SYSTEM::NAME "PATH-TST-TEST-PATHNAME"
            TYPE "ABC" SYSTEM::VERSION NIL)
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
            :NAME "path-tst-test-pathname" :TYPE "abc" :VERSION NIL)

(PARSE-NAMESTRING MY-SYMBOL)
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE "DISK00$ABT43"
            DIRECTORY "XCL.MAIN" SYSTEM::NAME "PATH-TST-TEST-PATHNAME"
            TYPE "ABC" SYSTEM::VERSION NIL)
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
            :NAME "path-tst-test-pathname" :TYPE "abc" :VERSION NIL)

#+XCL
(PARSE-NAMESTRING "bab:test-pathname.abc")
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE "$1$DUA70"
            DIRECTORY "43.BABYLON.REL2" SYSTEM::NAME
            "TEST-PATHNAME" TYPE "ABC" SYSTEM::VERSION NIL)

#+XCL
(PARSE-NAMESTRING "bab:test-pathname.abc;3")
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE "$1$DUA70"
            DIRECTORY "43.BABYLON.REL2" SYSTEM::NAME
            "TEST-PATHNAME" TYPE "ABC" SYSTEM::VERSION 3)

(PARSE-NAMESTRING PATHSTRING)
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE "DISK00$ABT43"
            DIRECTORY "XCL.MAIN" SYSTEM::NAME "PATH-TST-TEST-PATHNAME"
            TYPE "ABC" SYSTEM::VERSION NIL)
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
            :NAME "path-tst-test-pathname" :TYPE "abc" :VERSION NIL)

(PARSE-NAMESTRING "path-tst-test-pathname.abc" NIL)
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE "DISK00$ABT43"
            DIRECTORY "XCL.MAIN" SYSTEM::NAME "PATH-TST-TEST-PATHNAME"
            TYPE "ABC" SYSTEM::VERSION NIL)
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
            :NAME "path-tst-test-pathname" :TYPE "abc" :VERSION NIL)

#+XCL
(PARSE-NAMESTRING "sirius::disk00$abt43:[heicking]test-pathname.abc")
#+XCL
#S(PATHNAME SYSTEM::HOST "SIRIUS" SYSTEM::DEVICE "DISK00$ABT43"
            DIRECTORY "HEICKING" SYSTEM::NAME "TEST-PATHNAME"
            TYPE "ABC" SYSTEM::VERSION NIL)

#+XCL
(PARSE-NAMESTRING "sirius::disk00$abt43:[heicking]test-pathname.abc" "sirius")
#+XCL
#S(PATHNAME
SYSTEM::HOST "SIRIUS" SYSTEM::DEVICE "DISK00$ABT43" DIRECTORY "HEICKING"
SYSTEM::NAME "TEST-PATHNAME" TYPE "ABC" SYSTEM::VERSION NIL)

#+XCL
(PARSE-NAMESTRING "sirius::disk00$abt43:[heicking]test-pathname.abc" "orion")
#+XCL
ERROR

(PARSE-NAMESTRING "abc.123" NIL NIL :START 0 :END 5)
#+XCL
#S(PATHNAME SYSTEM::HOST
NIL SYSTEM::DEVICE "DISK00$ABT43" DIRECTORY "XCL.MAIN" SYSTEM::NAME "ABC" TYPE
"1" SYSTEM::VERSION NIL)
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
            :NAME "abc" :TYPE "1" :VERSION NIL)

(PARSE-NAMESTRING "abc.123" NIL NIL :START 2 :END 5)
#+XCL
#S(PATHNAME SYSTEM::HOST
NIL SYSTEM::DEVICE "DISK00$ABT43" DIRECTORY "XCL.MAIN" SYSTEM::NAME "C" TYPE "1"
SYSTEM::VERSION NIL)
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
            :NAME "c" :TYPE "1" :VERSION NIL)

#+XCL
(PARSE-NAMESTRING "babylon" NIL NIL :START 0 :END 3)
#+XCL
#S(PATHNAME SYSTEM::HOST
NIL SYSTEM::DEVICE "$1$DUA70" DIRECTORY "43.BABYLON.REL2" SYSTEM::NAME NIL TYPE
NIL SYSTEM::VERSION NIL)

#+XCL
(PARSE-NAMESTRING "babylon" NIL NIL :START 0 :END 7)
#+XCL
#S(PATHNAME SYSTEM::HOST
NIL SYSTEM::DEVICE "DISK00$ABT43" DIRECTORY "XCL.MAIN" SYSTEM::NAME "BABYLON"
TYPE NIL SYSTEM::VERSION NIL)

#+XCL
(PARSE-NAMESTRING "babylon" NIL *DEFAULT-PATHNAME-DEFAULTS* :START 0 :END 7)
#+XCL
#S(PATHNAME
SYSTEM::HOST NIL SYSTEM::DEVICE "DISK00$ABT43" DIRECTORY "XCL.MAIN" SYSTEM::NAME
"BABYLON" TYPE NIL SYSTEM::VERSION NIL)

(make-pathname :device nil :defaults *DEFAULT-PATHNAME-DEFAULTS*)
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE NIL
DIRECTORY NIL SYSTEM::NAME NIL TYPE "lsp" SYSTEM::VERSION :NEWEST)
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
            :NAME NIL :TYPE NIL :VERSION NIL)

#+XCL
(PARSE-NAMESTRING "babylon" NIL *DEFAULT-PATHNAME-DEFAULTS* :START 0 :END 3)
#+XCL
#S(PATHNAME
SYSTEM::HOST NIL SYSTEM::DEVICE "$1$DUA70" DIRECTORY "43.BABYLON.REL2"
SYSTEM::NAME NIL TYPE NIL SYSTEM::VERSION NIL)

;(PARSE-NAMESTRING "babylon.c.c" NIL NIL :JUNK-ALLOWED T)
;#S(PATHNAME
;SYSTEM::HOST NIL SYSTEM::DEVICE "DISK00$ABT43" DIRECTORY "XCL.MAIN" SYSTEM::NAME
;"BABYLON" TYPE "C" SYSTEM::VERSION NIL)

;(PARSE-NAMESTRING "babylon;c.c" NIL NIL :JUNK-ALLOWED T)
;#S(PATHNAME
;SYSTEM::HOST NIL SYSTEM::DEVICE "DISK00$ABT43" DIRECTORY "XCL.MAIN" SYSTEM::NAME
;"BABYLON" TYPE NIL SYSTEM::VERSION NIL)

#+XCL
(PARSE-NAMESTRING "babylon;c.c" NIL NIL :JUNK-ALLOWED NIL)
#+XCL
ERROR

#+XCL
(PARSE-NAMESTRING "babylon.c.c" NIL NIL :JUNK-ALLOWED NIL)
#+XCL
ERROR

#+XCL
(PARSE-NAMESTRING "babylon.c;c" NIL NIL :JUNK-ALLOWED NIL)
#+XCL
ERROR

#+XCL
(PARSE-NAMESTRING "babylon.c;" NIL NIL :JUNK-ALLOWED NIL)
#+XCL
#S(PATHNAME
SYSTEM::HOST NIL SYSTEM::DEVICE "DISK00$ABT43" DIRECTORY "XCL.MAIN" SYSTEM::NAME
"BABYLON" TYPE "C" SYSTEM::VERSION NIL)

#+XCL
(PARSE-NAMESTRING "babylon.c;5" NIL NIL :JUNK-ALLOWED NIL)
#+XCL
#S(PATHNAME
SYSTEM::HOST NIL SYSTEM::DEVICE "DISK00$ABT43" DIRECTORY "XCL.MAIN" SYSTEM::NAME
"BABYLON" TYPE "C" SYSTEM::VERSION 5)

;(MERGE-PATHNAME "test$$" MY-SYMBOL 10)   ERROR
;;
;(MERGE-PATHNAME "test$$" MY-SYMBOL)   ERROR
;
;(MERGE-PATHNAME "test$$" MY-PATHNAME)   ERROR
;
;(MERGE-PATHNAME "test$$")   ERROR

#+XCL
(MERGE-PATHNAMES "test$$")
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE
"DISK00$ABT43" DIRECTORY "XCL.MAIN" SYSTEM::NAME "TEST$$" TYPE "lsp"
SYSTEM::VERSION :NEWEST)

#+XCL
(MERGE-PATHNAMES "test$$" MY-SYMBOL)
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE
"DISK00$ABT43" DIRECTORY "XCL.MAIN" SYSTEM::NAME "TEST$$" TYPE "ABC"
SYSTEM::VERSION :NEWEST)

#+XCL
(MERGE-PATHNAMES "test$$" MY-SYMBOL 2)
#+XCL
#S(PATHNAME SYSTEM::HOST NIL
SYSTEM::DEVICE "DISK00$ABT43" DIRECTORY "XCL.MAIN" SYSTEM::NAME "TEST$$" TYPE
"ABC" SYSTEM::VERSION 2)

#+XCL
(MERGE-PATHNAMES "test$$" (PATHNAME MY-SYMBOL) 2)
#+XCL
#S(PATHNAME SYSTEM::HOST NIL
SYSTEM::DEVICE "DISK00$ABT43" DIRECTORY "XCL.MAIN" SYSTEM::NAME "TEST$$" TYPE
"ABC" SYSTEM::VERSION 2)

#+XCL
(MERGE-PATHNAMES "test$$" MY-STREAM 2)
#+XCL
#S(PATHNAME SYSTEM::HOST 16 SYSTEM::DEVICE
"DISK00$ABT43" DIRECTORY "XCL.MAIN" SYSTEM::NAME "TEST$$" TYPE :ESCAPE
SYSTEM::VERSION 2)


;(MERGE-PATHNAME MY-STRING MY-SYMBOL)   ERROR

#+XCL
(MAKE-PATHNAME :NAME "a" :HOST (QUOTE ORION))
#+XCL
#S(PATHNAME SYSTEM::HOST ORION
SYSTEM::DEVICE NIL DIRECTORY NIL SYSTEM::NAME "a" TYPE NIL SYSTEM::VERSION
:NEWEST)

#+XCL
(DEFMACRO TEST (&REST BODY) (\` (APPLY (FUNCTION MAKE-PATHNAME) (\,@ BODY))))
#+XCL
TEST

#+XCL
(setf a '(:host "sirius" :name "a"))
#+XCL
(:host "sirius" :name "a")

#+XCL
(TEST A)
#+XCL
#S(PATHNAME SYSTEM::HOST "sirius" SYSTEM::DEVICE NIL DIRECTORY NIL
SYSTEM::NAME "a" TYPE NIL SYSTEM::VERSION :NEWEST)

#+XCL
(SETF A (LIST* :DEVICE "disk00$abt43" A))
#+XCL
(:DEVICE "disk00$abt43" :HOST "sirius" :NAME "a")

#+XCL
(TEST A)
#+XCL
#S(PATHNAME SYSTEM::HOST "sirius" SYSTEM::DEVICE "disk00$abt43"
DIRECTORY NIL SYSTEM::NAME "a" TYPE NIL SYSTEM::VERSION :NEWEST)

#+XCL
(SETF A (LIST* :DIRECTORY "[heicking.comlisp]" A))
#+XCL
(:DIRECTORY
"[heicking.comlisp]" :DEVICE "disk00$abt43" :HOST "sirius" :NAME "a")

#+XCL
(TEST A)
#+XCL
#S(PATHNAME SYSTEM::HOST "sirius" SYSTEM::DEVICE "disk00$abt43"
DIRECTORY "[heicking.comlisp]" SYSTEM::NAME "a" TYPE NIL SYSTEM::VERSION
:NEWEST)

#+XCL
(SETF A (LIST* :TYPE "raf" A))
#+XCL
(:TYPE "raf" :DIRECTORY "[heicking.comlisp]"
:DEVICE "disk00$abt43" :HOST "sirius" :NAME "a")

#+XCL
(TEST A)
#+XCL
#S(PATHNAME SYSTEM::HOST "sirius" SYSTEM::DEVICE "disk00$abt43"
DIRECTORY "[heicking.comlisp]" SYSTEM::NAME "a" TYPE "raf" SYSTEM::VERSION
:NEWEST)

#+XCL
(SETF A (LIST* :VERSION 3 A))
#+XCL
(:VERSION 3 :TYPE "raf" :DIRECTORY
"[heicking.comlisp]" :DEVICE "disk00$abt43" :HOST "sirius" :NAME "a")

#+XCL
(TEST A)
#+XCL
#S(PATHNAME SYSTEM::HOST "sirius" SYSTEM::DEVICE "disk00$abt43"
DIRECTORY "[heicking.comlisp]" SYSTEM::NAME "a" TYPE "raf" SYSTEM::VERSION 3)

(MAPCAR (FUNCTION PATHNAMEP) (LIST PATHSYMBOL PATHPATH PATHSTRING))
(T T T)

#+XCL
(SETF MY-PATH (TEST A))
#+XCL
#S(PATHNAME SYSTEM::HOST "sirius" SYSTEM::DEVICE
"disk00$abt43" DIRECTORY "[heicking.comlisp]" SYSTEM::NAME "a" TYPE "raf"
SYSTEM::VERSION 3)

#+XCL
(MAPCAR (FUNCTION PATHNAME-HOST) (LIST MY-SYMBOL MY-STRING MY-STREAM MY-PATHNAME))
#+XCL
(NIL NIL NIL NIL)

#+XCL
(MAPCAR (FUNCTION PATHNAME-DEVICE) (LIST MY-SYMBOL MY-STRING MY-STREAM MY-PATHNAME))
#+XCL
("DISK00$ABT43" "DISK00$ABT43" "DISK00$ABT43" "DISK00$ABT43")

#+XCL
(MAPCAR (FUNCTION PATHNAME-DIRECTORY) (LIST MY-SYMBOL MY-STRING MY-STREAM MY-PATHNAME))
#+XCL
("XCL.MAIN" "XCL.MAIN" "XCL.MAIN" "XCL.MAIN")

(PROGN (CLOSE MY-STREAM) T)
T

#+XCL
(USER-HOMEDIR-PATHNAME)
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE
"DISK00$ABT43" DIRECTORY "HEICKING" SYSTEM::NAME NIL TYPE NIL SYSTEM::VERSION
NIL)

(PATHNAME "*.*")
#+XCL
#S(PATHNAME SYSTEM::HOST NIL SYSTEM::DEVICE "DISK00$ABT43"
DIRECTORY "HEICKING" SYSTEM::NAME "*" TYPE :WILD SYSTEM::VERSION NIL)
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
            :NAME :WILD :TYPE :WILD :VERSION NIL)

(progn (setf my-file (open "path-tst-non-existent-file.non"
                           :direction :input
                           :element-type 'string-char
                           :if-does-not-exist :create)) t)
t

(null (probe-file "path-tst-non-existent-file.non"))
NIL

(progn (close my-file) t)
t

(setf my-file (open "path-tst-non-existent-file.non"
                    :direction :io
                    :element-type 'string-char
                    :if-exists :error))
error

(progn (close my-file) t)
t

(null (setf my-file (open "path-tst-non-existent-file.non"
                          :direction :io
                          :element-type 'string-char
                          :if-exists :new-version)))
nil

(progn (close my-file) t)
t

(null (setf my-file (open "path-tst-non-existent-file.non"
                          :direction :io
                          :element-type 'string-char
                          :if-exists :rename)))
nil

(progn (close my-file) t)
t

(null (setf my-file (open "path-tst-non-existent-file.non"
                          :direction :io
                          :element-type 'string-char
                          :if-exists :rename-and-delete)))
nil

(progn (close my-file) t)
t

(null (setf my-file (open "path-tst-non-existent-file.non"
                          :direction :io
                          :element-type 'string-char
                          :if-exists :overwrite)))
nil

(progn (close my-file) t)
t

(null (setf my-file (open "path-tst-non-existent-file.non"
                          :direction :io
                          :element-type 'string-char
                          :if-exists :append)))
nil

(progn (close my-file) t)
t

(null (setf my-file (open "path-tst-non-existent-file.non"
                          :direction :io
                          :element-type 'string-char
                          :if-exists :supersede)))
nil

(progn (close my-file) t)
t

(setf my-file (open "path-tst-non-existent-file.non"
                    :direction :io
                    :element-type 'string-char
                    :if-exists nil))
nil

(progn (close my-file) t)
error

(setf my-file (open "non-existent-file.new"
                    :direction :io
                    :element-type 'string-char
                    :if-does-not-exist :error))
error

(progn (close my-file) t)
error

(truename "~/no/ such / path /  non-existent-file.new")
error

(null (setf my-file (open "non-existent-file.new"
                          :direction :io
                          :element-type 'string-char
                          :if-does-not-exist :create)))
nil

(progn (close my-file) t)
t

(null (setf my-file (open "path-tst-non-existent-file.non"
                          :direction :io
                          :element-type 'string-char
                          :if-does-not-exist nil)))
nil

(progn (close my-file) t)
t

(let ((*default-pathname-defaults* #p""))
  (multiple-value-bind (new-name pathname truename)
      (rename-file "path-tst-non-existent-file.non" "path-tst-file.da")
    (list (namestring new-name) (null pathname) (null truename))))
("path-tst-file.da" NIL NIL)

(close (open "path-tst-file.da" :direction :output :if-exists :rename-and-delete))
t

(pathnamep (probe-file "path-tst-test-pathname.abc"))
t

(progn (delete-file "path-tst-test-pathname.abc") t)
t

(progn (mapc #'delete-file (directory "non-existent-file.*")) t)
t

(progn (delete-file "path-tst-file.da") t)
t

(progn
 (setf (logical-pathname-translations "clocc")
       '(("**;*" "/usr/local/src/clocc/**/*"))
       (logical-pathname-translations "CL-LIBRARY")
       '((";**;*.*.*" "/tmp/clisp/"))
       (logical-pathname-translations "cl-systems")
       '((";**;*.*.*"  "/usr/share/common-lisp/systems/**/*.*")
         ("**;*.*.*"  "/usr/share/common-lisp/systems/**/*.*")
         (";*.*.*"  "/usr/share/common-lisp/systems/*.*")
         ("*.*.*"  "/usr/share/common-lisp/systems/*.*"))
       (logical-pathname-translations "TEST-SIMPLE")
       '(("*.*.*" "/usr/local/tmp/*.*.*")
         ("*.*" "/usr/local/tmp/*.*"))
       (logical-pathname-translations "TEST-SUBDIR")
       '(("**;*.*" "/usr/local/share/**/*.*")
         ("**;*.*.*" "/usr/local/share/**/*.*.*")
         (";**;*.*" "/usr/local/share/r/**/*.*")
         (";**;*.*.*" "/usr/local/share/r/**/*.*.*")))
 nil)
nil

(translate-logical-pathname "clocc:src;port;")
#P"/usr/local/src/clocc/src/port/"

(translate-pathname "foobar" "foo*" "*baz")
#P"barbaz"

(translate-pathname "foobarbazquux" "foo*baz*" "*baq*zot")
#P"barbaqquuxzot"

(translate-pathname "foobarbazquuxfff" "foo*baz*f?" "*baq*zot*")
#P"barbaqquuxfzotf"

(translate-pathname "uufoobarbazquuxfff" "u?foo*baz*f?" "**baq*zot*")
#P"ubarbaqquuxfzotf"

(translate-pathname "test.txt" "*.txt" "*.text")
#P"test.text"

(translate-pathname "foo/bar" "*/bar" "*/baz")
#P"foo/baz"

(translate-pathname "bar/foo" "bar/*" "baz/*")
#P"baz/foo"

(make-pathname :defaults "**/*.FASL" :host "CL-LIBRARY")
#+CLISP
#S(LOGICAL-PATHNAME :HOST "CL-LIBRARY" :DEVICE NIL
   :DIRECTORY (:RELATIVE :WILD-INFERIORS)
   :NAME :WILD :TYPE "FASL" :VERSION NIL)
#-CLISP
UNKNOWN

(make-pathname :defaults "/**/*.FASL" :host "CL-LIBRARY")
#+CLISP
#S(LOGICAL-PATHNAME :HOST "CL-LIBRARY" :DEVICE NIL
   :DIRECTORY (:ABSOLUTE :WILD-INFERIORS)
   :NAME :WILD :TYPE "FASL" :VERSION NIL)
#-CLISP
UNKNOWN

(logical-pathname ":")
#+CLISP
#S(LOGICAL-PATHNAME :HOST "" :DEVICE NIL :DIRECTORY (:ABSOLUTE)
                    :NAME NIL :TYPE NIL :VERSION NIL)
#-CLISP
UNKNOWN

(merge-pathnames (logical-pathname "cl-systems:") "metering.system")
#+CLISP
#S(LOGICAL-PATHNAME :HOST "CL-SYSTEMS" :DEVICE NIL :DIRECTORY (:ABSOLUTE)
                    :NAME "METERING" :TYPE "SYSTEM" :VERSION :NEWEST)
#-CLISP
UNKNOWN

(merge-pathnames (logical-pathname "cl-systems:") #P"metering.system")
#+CLISP
#S(LOGICAL-PATHNAME :HOST "CL-SYSTEMS" :DEVICE NIL :DIRECTORY (:ABSOLUTE)
                    :NAME "METERING" :TYPE "SYSTEM" :VERSION :NEWEST)
#-CLISP
UNKNOWN

(merge-pathnames (logical-pathname "clocc:clocc.lisp"))
#+CLISP
#S(logical-pathname :host "CLOCC" :device nil :directory (:absolute)
                    :name "CLOCC" :type "LISP" :version :newest)
#-CLISP
UNKNOWN

(merge-pathnames ".fas" (logical-pathname "clocc:src;cllib;xml.lisp"))
#+CLISP
#S(LOGICAL-PATHNAME :HOST "CLOCC" :DEVICE NIL :DIRECTORY
   (:ABSOLUTE "SRC" "CLLIB") :NAME "XML" :TYPE "FAS" :VERSION :NEWEST)
#-CLISP
UNKNOWN

(logical-pathname "clocc:;foo;bar;")
#+CLISP #S(LOGICAL-PATHNAME :HOST "CLOCC" :DEVICE :UNSPECIFIC
           :DIRECTORY (:RELATIVE "FOO" "BAR") :NAME NIL :TYPE NIL :VERSION NIL)
#-CLISP UNKNOWN

(logical-pathname "clocc:baz;quux.lisp.3")
#+CLISP #S(LOGICAL-PATHNAME :HOST "CLOCC" :DEVICE :UNSPECIFIC
           :DIRECTORY (:ABSOLUTE "BAZ") :NAME "QUUX" :TYPE "LISP" :VERSION 3)
#-CLISP UNKNOWN

(merge-pathnames (logical-pathname "clocc:;foo;bar;")
                 (logical-pathname "clocc:baz;quux.lisp.3"))
#+CLISP
#S(LOGICAL-PATHNAME :HOST "CLOCC" :DEVICE NIL :DIRECTORY
   (:ABSOLUTE "BAZ" "FOO" "BAR") :NAME "QUUX" :TYPE "LISP" :VERSION 3)
#-CLISP
UNKNOWN

(compile-file-pathname (logical-pathname "clocc:clocc.lisp"))
#+CLISP
#S(logical-pathname :host "CLOCC" :device nil :directory (:absolute)
                    :name "CLOCC" :type "FAS" :version :newest)
#-CLISP
UNKNOWN

(compile-file-pathname (logical-pathname "clocc:src;cllib;xml.lisp"))
#+CLISP
#S(LOGICAL-PATHNAME :HOST "CLOCC" :DEVICE NIL :DIRECTORY
   (:ABSOLUTE "SRC" "CLLIB") :NAME "XML" :TYPE "FAS" :VERSION :NEWEST)
#-CLISP
UNKNOWN

;; https://sourceforge.net/p/clisp/bugs/677/
(compile-file-pathname (logical-pathname "clocc:clocc.lisp")
                       :output-file "/tmp/Bug677/file-TEMP01.fas")
#+CLISP
#S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY (:ABSOLUTE "tmp" "Bug677")
            :NAME "file-TEMP01" :TYPE "fas" :VERSION :NEWEST)
#-CLISP
UNKNOWN

(parse-namestring "foo;bar;baz.fas.3" "clocc")
#+CLISP
#S(LOGICAL-PATHNAME :HOST "CLOCC" :DEVICE NIL
   :DIRECTORY (:ABSOLUTE "FOO" "BAR") :NAME "BAZ" :TYPE "FAS" :VERSION 3)
#-CLISP
UNKNOWN

(parse-namestring "foo;bar;baz.fas.3" nil (logical-pathname "clocc:"))
#+CLISP
#S(LOGICAL-PATHNAME :HOST "CLOCC" :DEVICE NIL
   :DIRECTORY (:ABSOLUTE "FOO" "BAR") :NAME "BAZ" :TYPE "FAS" :VERSION 3)
#-CLISP
UNKNOWN

(let* ((s "abcdefghijk")
       (d (make-array 5 :displaced-to s :displaced-index-offset 3
                        :element-type 'character)))
  (parse-namestring d nil nil :start 2 :end 4))
#+CLISP #S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
                    :NAME "fg" :TYPE NIL :VERSION NIL)
#-CLISP #P"fg"                  ; same as above

;; Relative
(translate-logical-pathname
 (merge-pathnames (logical-pathname "TEST-SUBDIR:;FOO;BAR;")
                  (logical-pathname "TEST-SIMPLE:ZOT.LISP")))
#+CLISP #S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY
                    (:ABSOLUTE "usr" "local" "share" "r" "foo" "bar")
                    :NAME "zot" :TYPE "lisp" :VERSION :NEWEST)
#-CLISP #p"/usr/local/share/r/foo/bar/zot.lisp"

;; Absolute
(translate-logical-pathname
 (merge-pathnames (logical-pathname "TEST-SUBDIR:FOO;BAR;")
                  (logical-pathname "TEST-SIMPLE:ZOT.LISP")))
#+CLISP #S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY
                    (:ABSOLUTE "usr" "local" "share" "foo" "bar")
                    :NAME "zot" :TYPE "lisp" :VERSION :NEWEST)
#-CLISP #p"/usr/local/share/foo/bar/zot.lisp"

(make-pathname :defaults "a.b" :name "c" :type nil)
#+CLISP #S(PATHNAME :HOST NIL :DEVICE NIL :DIRECTORY NIL
                    :NAME "c" :TYPE NIL :VERSION :NEWEST)
#-CLISP #p"c"

#+CLISP
(make-pathname :defaults #S(LOGICAL-PATHNAME :HOST "CL-LIBRARY" :DEVICE NIL
                            :DIRECTORY (:ABSOLUTE "FOO")
                            :NAME "BAR" :TYPE "BAZ" :VERSION 3))
#+CLISP
#S(LOGICAL-PATHNAME :HOST "CL-LIBRARY" :DEVICE NIL :DIRECTORY (:ABSOLUTE "FOO")
   :NAME "BAR" :TYPE "BAZ" :VERSION 3)

(defun foo (x host)
  (let ((dflt (make-pathname :directory '(:relative :wild-inferiors)
                             :type x :case :common)))
    (if host
        (make-pathname :defaults dflt :host host :case :common)
        (make-pathname :defaults dflt :case :common))))
foo

(defun path= (p1 p2)
  (flet ((path-components (p)
           (list (type-of p) (pathname-host p) (pathname-device p)
                 (pathname-directory p) (pathname-name p) (pathname-type p)
                 (pathname-version p))))
    (or (equal p1 p2) (list (path-components p1) (path-components p2)))))
path=

;; :defaults arg is not subject to :case conversion
(string= "c" (pathname-type (foo "c" nil) :case :common))
t
(string= "C" (pathname-type (foo "C" nil) :case :common))
t

;; :case is ignored for logical pathnames
(string= "C" (pathname-type (foo "c" "CLOCC") :case :common))
t
(string= "c" (pathname-type (foo "C" "CLOCC") :case :common))
t

(namestring (logical-pathname "foo:bar;baz"))
"FOO:BAR;BAZ"

(let* ((foo (copy-seq "abcdefghijkl"))
       (bar (make-array 5 :displaced-to foo :displaced-index-offset 2
                          :element-type 'character))
       (path (make-pathname :directory bar)))
  (setf (aref foo 3) #\/)
  (path= path (make-pathname :directory (pathname-directory path))))
t

(string= (namestring (make-pathname :name "FOO" :case :common
                                    :defaults #P"/home/kent/"))
         (namestring #P"/home/kent/foo"))
t

(make-pathname :directory '(:absolute :wild) :host nil :device nil
               :name nil :type nil :version nil)
#P"/*/"

(pathname-match-p "foo" "foo.*")           T
(let ((pn1 (make-pathname :directory '(:relative :wild)))
      (pn2 (make-pathname :directory '(:relative))))
  (pathname-match-p pn1 pn2))
NIL

(translate-pathname "foo" "foo.*" "bar")   #p"bar"
(translate-pathname "foo" "foo.*" "bar.*") #p"bar"
(progn
  (setf (logical-pathname-translations "FOO") '(("FOO:**;*" "/foo/**/*")))
  (translate-logical-pathname "foo:bar;baz;zot.txt"))
#P"/foo/bar/baz/zot.txt"
(progn
  (setf (logical-pathname-translations "FOO") '(("**;*" "/foo/**/*")))
  (translate-logical-pathname "foo:bar;baz;zot.txt"))
#P"/foo/bar/baz/zot.txt"

(pathname "/foo/bar/../baz///zot//.././zoo")
#P"/foo/baz/zoo"

(pathname-directory "../../../")
(:RELATIVE :UP :UP :UP)

(listp (directory (make-pathname :version :wild
                                 :defaults (logical-pathname "FOO:"))))
T

(pathname-directory (make-pathname :version :wild
                                   :defaults (logical-pathname "FOO:")))
(:ABSOLUTE)

#+clisp
(let ((f "this-directory-does-not-exist")
      (custom:*merge-pathnames-ansi* t))
  (when (directory f) (delete-file f))
  (list
   (let ((d (ext:string-concat f "/")))
     (when (directory d) (ext:delete-directory d))
     (directory d))
   (directory (ext:string-concat f "/*"))))
#+clisp (NIL NIL)

;; <http://www.ai.mit.edu/projects/iiip/doc/CommonLISP/HyperSpec/Body/sec_19-3-2-1.html>
(pathname-device (logical-pathname "FOO:"))
:UNSPECIFIC

(let* ((old "path-tst-foo-bar.old")
       (new (make-pathname :type "new" :defaults old)))
  (with-open-file (s old :direction :output #+(or CMU SBCL) :if-exists #+(or CMU SBCL) :supersede) (write-line "to be renamed" s))
  (unwind-protect
       (list (list (not (not (probe-file old))) (probe-file new))
             (length (multiple-value-list (rename-file old new)))
             (list (probe-file old) (not (not (probe-file new)))))
    (delete-file new)))
((T NIL) 3 (NIL T))

#+clisp
(let ((src "src-file") (dst "dst-file"))
  (open src :direction :probe :if-does-not-exist :create) ; touch
  (open dst :direction :probe :if-does-not-exist :create) ; touch
  (unwind-protect
       (handler-case
           (multiple-value-list (rename-file src dst :if-exists :error))
         (error (e) (princ-error e) :good))
    (delete-file src)
    (delete-file dst)))
#+clisp :GOOD

#+clisp
(let ((src "src-file") (dst "dst-file"))
  (open src :direction :probe :if-does-not-exist :create) ; touch
  (open dst :direction :probe :if-does-not-exist :create) ; touch
  (unwind-protect
       (equal (truename dst)
              (nth-value 2 (rename-file src dst :if-exists :overwrite)))
    (delete-file src)
    (delete-file dst)))
#+clisp T

(wild-pathname-p (make-pathname :version :wild))   T

(pathname-version (merge-pathnames (make-pathname)
                                   (make-pathname :version :newest)
                                   nil))
:NEWEST

(pathname-version (merge-pathnames (make-pathname)
                                   (make-pathname :version nil)
                                   :newest))
:NEWEST

;; directory may not return wild pathnames
(remove-if-not #'wild-pathname-p
               (directory (make-pathname :name :wild :type :wild
                                         :version :wild)))
NIL

(let ((file "path-tst-this-is-a-temp-file-to-be-removed-immediately"))
  (unwind-protect
       (let ((d (directory (make-pathname
                            :defaults (open file :direction :probe
                                        :if-does-not-exist :create)
                            :version :wild))))
         (list (= (length d) 1)
               (notany #'wild-pathname-p d)
               (path= (car d) (truename file))))
    (delete-file file)))
(T T T)

(first (pathname-directory (translate-pathname
                            "foo/bar/baz" #p"" #p"" :absolute t)))
:ABSOLUTE

(let ((file "path-tst-this-is-a-temp-file-to-be-removed-immediately.lisp"))
  (unwind-protect
       (let* ((p (pathname (open file :direction :probe
                                 :if-does-not-exist :create)))
              (p1 (make-pathname :type nil :defaults p)))
         (when (probe-file p1) (delete-file p1)) ; just in case
         (list (not (null (probe-file p))) ; just created
               (null (probe-file p1))      ; just deleted
               (let ((*default-pathname-defaults* ; 19.2.3 !!!
                      (make-pathname :type "lisp")))
                 (not (null (probe-file p1))))))
    (delete-file file)))
(T T T)

(let ((file "path-tst-this-is-a-temp-file-to-be-removed-immediately"))
  (unwind-protect
       (let* ((p (pathname (open file :direction :probe
                                 :if-does-not-exist :create))))
         (list (not (null (probe-file p))) ; just created
               (with-open-file (s p)
                 (let ((*default-pathname-defaults*
                        (make-pathname :type "lisp")))
                   ;; despite 19.2.3, S is not subject to
                   ;; *DEFAULT-PATHNAME-DEFAULTS*!
                   (not (null (probe-file s)))))))
    (delete-file file)))
(T T)

(let ((file "path-tst-this-is-a-temp-file-to-be-removed-immediately"))
  (unwind-protect
       (with-open-file (s file :direction :output)
         (list (not (null (probe-file file)))
               (not (null (probe-file s)))
               (path= (truename s) (truename file))))
    (delete-file file)))
(T T T)

(let ((file "path-tst-this-is-a-temp-file-to-be-removed-immediately"))
  (unwind-protect
       (with-open-file (s file :direction :output)
         (path= (truename (enough-namestring s))
                (truename (enough-namestring (truename s)))))
    (delete-file file)))
T

(multiple-value-list
 (parse-namestring (make-array 0 :element-type 'character
                                 :displaced-to "foo"
                                 :displaced-index-offset 1)))
(#P"" 0)

#+(and clisp win32)
(absolute-pathname (make-pathname :device :wild))
#+(and clisp win32)
error

(let ((home (user-homedir-pathname)))
  (or (null home) (not (not (pathnamep home)))))
T

(let ((home (user-homedir-pathname nil)))
  (or (null home) (not (not (pathnamep home)))))
T

(let ((home (user-homedir-pathname :unspecific)))
  (or (null home) (not (not (pathnamep home)))))
T

;; Check that LOAD can load a file "abazonk.lisp" even if a
;; directory "abazonk" exists.
#+clisp
(let* ((n "path-tst-abazonk")
       (f (ext:string-concat n ".lisp"))
       (d (ext:string-concat n "/")))
  (with-open-file (s f :direction :output)
    (prin1 `(ext:delete-directory ,d) s))
  (ensure-directories-exist d)
  (list (ext:probe-directory d)
        (string= n (pathname-name (load n)))
        (not (null (delete-file f)))
        (ext:probe-directory d)))
#+clisp (T T T NIL)

#+clisp
(let* ((n "path-tst-abazonk-logical")
       (custom:*parse-namestring-ansi* t)
       (f (ext:string-concat n ".lisp"))
       (d (ext:string-concat n "/")))
  (with-open-file (s f :direction :output)
    (prin1 `(ext:delete-directory ,d) s))
  (ensure-directories-exist d)
  (setf (logical-pathname-translations "FOO") '(("*" "./*")))
  (list (ext:probe-directory d)
        (string= n (pathname-name (load (ext:string-concat "FOO:" n))))
        (not (null (delete-file f)))
        (ext:probe-directory d)))
#+clisp (T T T NIL)

;; check that we can compile files in ansi mode
(let ((f "path-tst-compile-file-ansi-pathname.lisp")
      #+clisp (custom:*print-pathnames-ansi* t))
  (with-open-file (s f :direction :output :if-exists :supersede)
    (format s "(defparameter *pathname-var*
  #.(make-pathname :name \"foo.bar\" :type nil))~%"))
  (unwind-protect (progn (load (compile-file f))
                         (pathname-name *pathname-var*))
    (post-compile-file-cleanup f)))
"foo.bar"

(let ((f "path-tst-compile-file-pathname.lisp") cf cfp)
  (with-open-file (s f :direction :output :if-exists :supersede)
    (format s "(defun cfp-test () #.*compile-file-truename*)~%"))
  (setq cf (compile-file f)
        cfp (truename (compile-file-pathname f)))
  (load cf)
  (unwind-protect
       (list (path= cf cfp)
             (path= (truename f) (cfp-test)))
    (post-compile-file-cleanup f)))
(T T)

(let ((f (logical-pathname "FOO:path-tst-compile-file-pathname.lisp")) cf cfp)
  (with-open-file (s f :direction :output :if-exists :supersede)
    (type-of (truename s))
    (format s "(defun cfp-test () #.*compile-file-truename*)~%"))
  (setq cf (compile-file f)
        cfp (truename (compile-file-pathname f)))
  (load (open cf :direction :probe :if-does-not-exist :error))
  (unwind-protect
       (list (path= cf cfp)
             (path= (truename f) (cfp-test)))
    (post-compile-file-cleanup f)))
(T T)

(let ((f "path-tst-compile-file-pathname.lisp"))
  (with-open-file (s f :direction :output :if-exists :supersede
                     :if-does-not-exist :create)
    (format s "(defun cfp-test () #.*compile-file-pathname*)~%"))
  (setq cf (compile-file f))
  (load (open cf :direction :probe :if-does-not-exist :error))
  (unwind-protect (path= (cfp-test) (merge-pathnames f))
    (post-compile-file-cleanup f)))
T

;; it is not clear whether this behavior is correct...
;; http://groups.google.com/group/comp.lang.lisp/browse_thread/thread/0d9876beeb52b67d
(let* ((l "path-tst-compile-file-pathname.lisp")
       (f (compile-file-pathname l)))
  (unwind-protect
       (progn (with-open-file (ls l :direction :output :if-exists :supersede)
                (format ls "(defun f () t)~%"))
              (list
               (with-open-file (fs f :direction :output :if-exists :supersede)
                 (format fs #1="first line") (terpri fs)
                 (compile-file l :output-file fs)
                 (open-stream-p fs))
               (with-open-file (fs f :direction :input)
                 (string= #1# (read-line fs)))))
    (post-compile-file-cleanup l)))
#+(or CLISP SBCL) (T T)
#-(or CLISP SBCL) UNKNOWN

(compile-file-pathname "foo" :OUTPUT-FILE (logical-pathname "SYS:foo.fas"))
#+CLISP #S(LOGICAL-PATHNAME :HOST "SYS" :DEVICE NIL :DIRECTORY (:ABSOLUTE)
                            :NAME "FOO" :TYPE "FAS" :VERSION :NEWEST)
#-CLISP UNKNOWN

(translate-logical-pathname (logical-pathname "SYS:FOO.LISP"))
#+CLISP #p"/foo.lisp"
#-CLISP UNKNOWN

;; ensure that when "foo" is a file, (directory "foo/") returns NIL
(let* ((f "path-tst-foo") r (f1 (concatenate 'string f "/")))
  (delete-file f)
  (push (directory f) r)
  (push (directory f1) r)
  (open f :direction :probe :if-does-not-exist :create)
  (let ((dir (directory f)) (tn (list (truename f))))
    (push (or (equalp dir tn)
              (list (mapcar #'path-components dir)
                    (mapcar #'path-components tn)))
          r))
  (push (directory f1) r)
  (delete-file f)
  (push (directory f) r)
  (push (directory f1) r)
  (nreverse r))
(NIL NIL T NIL NIL NIL)

;; getenv
(getenv "NO_SUCH_ENV_VAR")              NIL
(setf (getenv "NO_SUCH_ENV_VAR") "FOO") "FOO"
(getenv "NO_SUCH_ENV_VAR")              "FOO"
(setf (getenv "NO_SUCH_ENV_VAR") "")    ""
(getenv "NO_SUCH_ENV_VAR")              ""
(setf (getenv "NO_SUCH_ENV_VAR") NIL)   NIL
(getenv "NO_SUCH_ENV_VAR")              NIL

;; LOAD-LOGICAL-PATHNAME-TRANSLATIONS
;; getenv #1
(unwind-protect
     (progn
       (setf (logical-pathname-translations "FOO") nil
             (getenv "LOGICAL_HOST_FOO")
             (write-to-string '(("FOO:**;*" "/foo/**/*"))))
       (and (load-logical-pathname-translations "FOO")
            (cadar (logical-pathname-translations "FOO"))))
  (setf (getenv "LOGICAL_HOST_FOO") nil)) "/foo/**/*"
(translate-logical-pathname "foo:bar;baz;zot.txt") #P"/foo/bar/baz/zot.txt"

;; getenv #2
(unwind-protect
     (progn
       (setf (logical-pathname-translations "FOO") nil
             (getenv "LOGICAL_HOST_FOO_FROM") "FOO:**;*"
             (getenv "LOGICAL_HOST_FOO_TO") "/foo/**/*")
       (and (load-logical-pathname-translations "FOO")
            (cadar (logical-pathname-translations "FOO"))))
  (setf (getenv "LOGICAL_HOST_FOO_FROM") nil
        (getenv "LOGICAL_HOST_FOO_TO") nil)) "/foo/**/*"
(translate-logical-pathname "foo:bar;baz;zot.txt") #P"/foo/bar/baz/zot.txt"

;; one file - many hosts (Allegro style)
#+clisp
(let ((file (first *load-logical-pathname-translations-database*)))
  (unwind-protect
       (let ((*load-paths* nil) (*load-verbose* t))
         (setf (logical-pathname-translations "FOO") nil)
         (with-open-file (f file :direction :output)
           (format f "~S~%~S~%" "FOO" ''(("FOO:**;*" "/foo/**/*"))))
         (and (load-logical-pathname-translations "FOO")
              (cadar (logical-pathname-translations "FOO"))))
    (delete-file file)))
#+clisp "/foo/**/*"
#+clisp (translate-logical-pathname "foo:bar;baz;zot.txt")
#+clisp #P"/foo/bar/baz/zot.txt"

;; one file - one host (CMUCL style)
#+clisp
(let* ((dir (make-pathname :directory (list :relative (pathname-name (first *load-logical-pathname-translations-database*)))))
       (file (merge-pathnames "FOO" dir)))
  (unwind-protect
       (let ((*load-paths* nil) (*load-verbose* t))
         (setf (logical-pathname-translations "FOO") nil)
         (ext:make-directory dir)
         (with-open-file (f file :direction :output)
           (format f "~S~%" '(("FOO:**;*" "/foo/**/*"))))
         (and (load-logical-pathname-translations "FOO")
              (cadar (logical-pathname-translations "FOO"))))
    (delete-file file)
    (ext:delete-directory dir)))
#+clisp "/foo/**/*"
#+clisp (translate-logical-pathname "foo:bar;baz;zot.txt")
#+clisp #P"/foo/bar/baz/zot.txt"

;; https://sourceforge.net/p/clisp/bugs/363/
(dolist (dflt (list #P"/home/" (logical-pathname "CLOCC:SRC;PORT;")))
  (dolist (dir '(NIL (:absolute "foo")))
    (assert (equal dir (pathname-directory (make-pathname :directory dir
                                                          :defaults dflt))))))
NIL

;; https://sourceforge.net/p/clisp/bugs/364/
(make-pathname :directory '(:absolute :wild-inferiors "subdir"))
#P"/**/subdir/"

;; https://sourceforge.net/p/clisp/bugs/504/
;; wild subdirectory
#+clisp
(let* ((lpd (pathname "path-tst-load-path-dir/"))
       (custom:*merge-pathnames-ansi* t)
       (file (merge-pathnames
              (first *load-logical-pathname-translations-database*)
              lpd)))
  (unwind-protect
       (let ((*load-paths* (list (merge-pathnames "**/" lpd)))
             (*load-verbose* t))
         (ext:make-directory lpd)
         (setf (logical-pathname-translations "FOO") nil)
         (with-open-file (f file :direction :output)
           (format f "~S~%~S~%" "FOO" ''(("FOO:**;*" "/foo/**/*"))))
         (and (load-logical-pathname-translations "FOO")
              (cadar (logical-pathname-translations "FOO"))))
    (delete-file file)
    (ext:delete-directory lpd)))
#+clisp "/foo/**/*"
#+clisp (translate-logical-pathname "foo:bar;baz;zot.txt")
#+clisp #P"/foo/bar/baz/zot.txt"

#+clisp
(let* ((lpd (pathname "path-tst-load-path-dir/"))
       (custom:*merge-pathnames-ansi* t)
       (dir (make-pathname :directory (append (pathname-directory lpd) (list (pathname-name (first *load-logical-pathname-translations-database*))))))
       (file (merge-pathnames "FOO" dir)))
  (unwind-protect
       (let ((*load-paths* (list (merge-pathnames "**/" lpd)))
             (*load-verbose* t))
         (setf (logical-pathname-translations "FOO") nil)
         (ext:make-directory lpd)
         (ext:make-directory dir)
         (with-open-file (f file :direction :output)
           (format f "~S~%" '(("FOO:**;*" "/foo/**/*"))))
         (and (load-logical-pathname-translations "FOO")
              (cadar (logical-pathname-translations "FOO"))))
    (delete-file file)
    (ext:delete-directory dir)
    (ext:delete-directory lpd)))
#+clisp "/foo/**/*"
#+clisp (translate-logical-pathname "foo:bar;baz;zot.txt")
#+clisp #P"/foo/bar/baz/zot.txt"

#+clisp (ext:make-directory "path-tst-foo/") #+clisp T
(defparameter *dir* (directory "path-tst-foo/" :full t)) *DIR*
(cdr *dir*) NIL
(length (car *dir*)) 4
(equal (caar *dir*) (cadar *dir*)) T
(equal (caar *dir*) (car (directory "path-tst-foo/"))) T
#+clisp (ext:rename-directory "path-tst-foo/" "path-tst-bar/") #+clisp T
#-clisp (rename-file "path-tst-foo/" "path-tst-bar/") #-clisp #p"path-tst-bar/"
(equal (cddar (directory "path-tst-bar/" :full t)) (cddar *dir*)) T
(directory "path-tst-foo/") NIL
#+clisp (ext:delete-directory "path-tst-bar/")
#-clisp (delete-file "path-tst-bar/") T
(directory "path-tst-bar/" :full t) NIL
(pathname-version (car (directory "./"))) :NEWEST

;; https://sourceforge.net/p/clisp/bugs/724/
(let* ((wd (ensure-directories-exist "bug-724/"))
       (f1 (open (merge-pathnames wd "file")
                 :direction :probe :if-does-not-exist :create))
       (f2 (open (merge-pathnames wd "file.txt")
                 :direction :probe :if-does-not-exist :create))
       (pat (make-pathname :name :wild :type :wild :version :wild :defaults wd))
       (*default-pathname-defaults* (ext:probe-pathname ".")))
  (unwind-protect
       (list (sort (mapcar #'enough-namestring (directory pat)) #'string<)
             (pathname-match-p f1 pat)
             (pathname-match-p f2 pat))
    (delete-file f1)
    (delete-file f2)
    #+clisp (ext:delete-directory wd)
    #-clisp (delete-file wd)))
(("bug-724/file" "bug-724/file.txt") T T)

(let (lp) ; https://sourceforge.net/p/clisp/bugs/584/: bind *load-pathname* to the original arg
  (setf (logical-pathname-translations "FOO") '(("*" "./*")))
  (setq lp (logical-pathname "FOO:load-test"))
  (with-open-file (o lp :direction :output)
    (write-line "(defparameter *load-var* *load-pathname*)" o))
  (unwind-protect (list (equalp (truename lp) (load lp))
                        (equalp (merge-pathnames lp) *load-var*))
    (delete-file lp)
    (setf (logical-pathname-translations "FOO") NIL)))
(T T)

#+clisp
(let ((f "path-tst-my-file") tn)
  (unwind-protect
       (progn
         (setq tn (truename
                   (open f :direction :probe :if-does-not-exist :create)))
         (multiple-value-bind (tn1 _ fwd) (ext:probe-pathname f)
           (list (equal tn (probe-file f))
                 (equal tn tn1)
                 (= (file-write-date tn) fwd)
                 (equal tn (ext:probe-pathname (concatenate 'string f "/")))
                 (equal tn (ext:probe-pathname
                            (concatenate 'string f "///"))))))
    (delete-file tn)))
#+clisp (T T T T T)

#+clisp
(let* ((d "path-tst-my-dir") (d1 (concatenate 'string d "/")) tn)
  (unwind-protect
       (progn
         (make-directory d1)
         (multiple-value-bind (tn1 d2 fwd) (ext:probe-pathname d)
           (setq tn (truename d1)
                 d2 (directory tn :full t))
           (list (equal tn tn1)
                 (equal tn (ext:probe-pathname d1))
                 (null (cdr d2)) (not (null (car d2)))
                 (= (apply #'encode-universal-time (third (car d2))) fwd)
                 (equal tn (ext:probe-pathname
                            (concatenate 'string d "///"))))))
    (ext:delete-directory tn)))
#+clisp (T T T T T T)

#+clisp
(let* ((d "path-tst-my-dir/")
       (dirs** (concatenate 'string d "**/"))
       (dirs* (concatenate 'string d "*/"))
       (files** (concatenate 'string d "**/*"))
       (files* (concatenate 'string d "*/*")))
  (unwind-protect
       (flet ((mkdir (s)
                (make-directory (concatenate 'string d s))
                (open (concatenate 'string d s "f")
                      :direction :probe :if-does-not-exist :create))
              (cmp (l1 l2) (list (length l1) (equalp l1 (mapcar #'first l2)))))
         (mkdir "")
         (mkdir "d1/") (mkdir "d1/s1/") (mkdir "d1/s2/")
         (mkdir "d2/") (mkdir "d2/s1/") (mkdir "d2/s2/")
         (list (cmp (directory dirs*) (directory dirs* :full t))
               (cmp (print(directory dirs**)) (print(directory dirs** :full t)))
               (cmp (directory files*) (directory files* :full t))
               (cmp (directory files**) (directory files** :full t))))
    (rmrf d)))
#+clisp ((2 T) (7 T) (2 T) (7 T))

#+clisp (consp (show (multiple-value-list (ext:probe-pathname "/")))) #+clisp T

#+(and clisp unix)
(equalp (show (multiple-value-list (ext:probe-pathname "/etc")))
        (show (multiple-value-list (ext:probe-pathname "/etc/"))))
#+(and clisp unix) T

#+clisp
(equalp
 (show (multiple-value-list (ext:probe-pathname (ext:default-directory))))
 (show (multiple-value-list (ext:probe-pathname ""))))
#+clisp T

#+clisp
(let* ((path "test-pathname")
       (s1 (open path :direction :probe :if-does-not-exist :create))
       (s2 (open path :direction :input)))
  (unwind-protect
       (let ((p-p (show (multiple-value-list (ext:probe-pathname path))))
             (p-c (show (multiple-value-list (ext:probe-pathname s1))))
             (p-o (show (multiple-value-list (ext:probe-pathname s2)))))
         (list (equalp p-p p-c) (equalp p-p p-o) (equalp p-c p-o)))
    (close s2)
    (delete-file s1)))
#+clisp (T T T)

;; top-level directory on disk C
#+(and clisp win32) (pathname-directory (ext:probe-pathname "c:/"))
#+(and clisp win32) (:ABSOLUTE)

;; default directory on disk C
#+(and clisp win32)
(let ((p (ext:probe-pathname "c:")))
  (list (pathname-name p) (pathname-type p)))
#+(and clisp win32) (NIL NIL)

#+(and clisp win32)
(equalp (multiple-value-list (ext:probe-pathname "/"))
        (multiple-value-list (ext:probe-pathname ; default device
                              (make-pathname :directory '(:absolute) :defaults
                                             (ext:default-directory)))))
#+(and clisp win32) T

#+(and clisp unicode (not macos))
(block test-weird-pathnames
  (handler-bind ((parse-error
                  ;; https://sourceforge.net/p/clisp/mailman/message/20057056/
                  ;; some systems, e.g., OSX PPC 10.4.11 (Darwin Kernel
                  ;; Version 8.11.0), allow only ASCII pathnames
                  (handler-return test-weird-pathnames '(T NIL T T))))
    (letf* ((custom:*pathname-encoding* charset:iso-8859-1) ; 1:1
            (weird (concatenate 'string "weird" (string (code-char 160))))
            (dir (list (make-pathname :version :newest
                                      :defaults (absolute-pathname weird)))))
      (open weird :direction :probe :if-does-not-exist :create) ; touch
      (unwind-protect
           (cons
            (equal (directory "weird*") dir)
            (letf ((custom:*pathname-encoding* charset:ascii))
              (list (appease-cerrors (directory "weird*"))
                    (handler-bind ((simple-charset-type-error
                                    (lambda (c)
                                      (princ-error c)
                                      (store-value charset:iso-8859-1))))
                      (equal (directory "weird*") dir))
                    (eq custom:*pathname-encoding* charset:iso-8859-1))))
        (delete-file weird)))))
#+(and clisp unicode (not macos)) (T NIL T T)

;; DOS attack: bad pathnames in search can break LOAD
;; http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=443520
;; https://sourceforge.net/p/clisp/mailman/message/19813221/
#+(and clisp unicode (not macos))
(letf* ((custom:*pathname-encoding* charset:iso-8859-1) ; 1:1
        (weird (concatenate 'string "weird" (string (code-char 160))))
        (good "path-tst-good-file") (dir "path-tst-load-weird-dir/")
        (custom:*load-paths* (list (concatenate 'string dir "**"))))
  (rmrf dir)
  (ext:make-directory dir)
  (open (concatenate 'string dir weird) :direction :probe
        :if-does-not-exist :create)
  (with-open-file (os (concatenate 'string dir good ".lisp")
                      :direction :output)
    (format os "(defparameter *load-var* 1234)~%"))
  (unwind-protect
       (list (letf ((custom:*pathname-encoding* charset:ascii))
               (load good)
               *load-var*)
             (eq custom:*pathname-encoding* charset:iso-8859-1))
    (rmrf dir)))
#+(and clisp unicode (not macos)) (1234 T)

#+clisp ;; https://sourceforge.net/p/clisp/bugs/579/
(let* ((dir "tmp-dir/")
       (file (ext:string-concat dir "foo.lisp")))
  (ext:make-directory dir)
  (with-open-file (out file :direction :output)
    (write-line "(defparameter *load-var* 100)" out))
  (unwind-protect
       (list (load "foo" :if-does-not-exist nil)
             (equalp (load file) (truename file)) *load-var*
             (let ((*load-paths* (list dir)))
               (setq *load-var* 3) (load "foo") *load-var*)
             (let ((*load-paths* (list dir))
                   (*default-pathname-defaults* (ext:cd)))
               (setq *load-var* 3) (load "foo" :if-does-not-exist nil) *load-var*)
             (block nil
               (handler-bind ((file-error (lambda (c) (princ c) (return 'file-error))))
                 (require "foo")))
             (let ((*load-paths* (list dir)))
               (setq *load-var* 3) (require "foo") *load-var*)
             (let ((*load-paths* (list dir))
                   (*default-pathname-defaults* (ext:cd)))
               (setq *load-var* 3) (require "foo") *load-var*))
    (delete-file file)
    (ext:delete-directory dir)))
#+clisp (NIL T 100 100 3 FILE-ERROR 100 100)

#+clisp
(let* ((files (directory #1=#P"../**/*" :if-does-not-exist :discard))
       (1st (car files))
       (copy (make-pathname :directory (pathname-directory 1st)
                            :name (pathname-name 1st)
                            :type (pathname-type 1st))))
  (format t "~&~:D file~:P under ~S~%" (length files)
          (ext:probe-pathname
           (make-pathname :directory (butlast (pathname-directory #1#) 1))))
  (list (delete-duplicates (mapcar #'pathname-version files))
        (equalp (ext:probe-pathname copy) 1st)
        (equalp (probe-file copy) 1st)
        (equalp (truename copy) 1st)))
#+clisp ((:NEWEST) T T T)

#+clisp
(let* ((dirs (directory #1=#P"../**/*/" :if-does-not-exist :discard))
       (1st (car dirs))
       (copy (make-pathname :directory (pathname-directory 1st)
                            :name (pathname-name 1st)
                            :type (pathname-type 1st))))
  (format t "~&~:D director~:@P under ~S~%" (length dirs)
          (ext:probe-pathname
           (make-pathname :directory (butlast (pathname-directory #1#) 2))))
  (list (delete-duplicates (mapcar #'pathname-version dirs))
        (equalp (ext:probe-pathname copy) 1st)
        (equalp (truename copy) 1st)))
#+clisp ((:NEWEST) T T)

;; https://sourceforge.net/p/clisp/bugs/679/
#+unix (pathnamep (truename "/dev/fd/0"))
#+unix #.(if (member (ext:operating-system-type) '("AIX" "Haiku" "Minix" "Windows") :test #'equal) 'ERROR 'T)
#+unix (pathnamep (truename "/dev/fd/1"))
#+unix #.(if (member (ext:operating-system-type) '("AIX" "Haiku" "Minix" "Windows") :test #'equal) 'ERROR 'T)
#+unix (pathnamep (truename "/dev/fd/2"))
#+unix #.(if (member (ext:operating-system-type) '("AIX" "Haiku" "Minix" "Windows") :test #'equal) 'ERROR 'T)


(symbols-cleanup
 '(*dir* a test my-string my-symbol pathstring pathsymbol pathpath
   my-path path= my-stream my-file *pathname-var* cfp-test *load-var*))
()
