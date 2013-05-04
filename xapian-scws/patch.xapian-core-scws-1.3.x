*** xapian-core-1.3.0_svn16982/configure.ac	2012-12-27 14:11:05.000000000 +0800
--- xapian-core-scws-1.3.0_svn16982/configure.ac	2012-12-28 12:42:13.000000000 +0800
***************
*** 987,992 ****
--- 987,1048 ----
      [Define if you want a log of methods called and other debug messages])
  fi
  
+ dnl **********************
+ dnl * Check scws library *
+ dnl **********************
+ dnl hightman.20110411: See if we want to use scws as default tokenizer
+ SCWS_DIR=""
+ AC_MSG_CHECKING(for scws)
+ AC_ARG_WITH(scws,
+   [AS_HELP_STRING([--with-scws@<:@=DIR@:>@], [use scws as default tokenizer, DIR is the install PREFIX of scws])],
+   [ ],[ with_scws=no ]
+ )
+ 
+ if test "$with_scws" = "no"; then
+   AC_MSG_RESULT(no)
+ else
+   # Check header file
+   if test "$with_scws" = "yes"; then
+ 	searchdirs="/usr /usr/local /usr/local/scws /opt/local"
+ 	for tmpdir in $searchdirs ; do
+ 	  if test -f $tmpdir/include/scws/scws.h ; then
+ 		SCWS_DIR=$tmpdir
+ 		break
+ 	  fi
+ 	done
+ 	if test "$SCWS_DIR" = ""; then
+ 	  AC_MSG_RESULT(no)
+ 	  AC_MSG_ERROR([scws not found on default search directories, specify DIR plz...])
+ 	fi
+   elif test -f $withval/include/scws/scws.h ; then
+ 	SCWS_DIR=$withval
+   else
+ 	AC_MSG_RESULT(no)
+ 	AC_MSG_ERROR([Invalid scws directory, unable to find the scws.h under $withval/include/scws])
+   fi
+   AC_MSG_RESULT([yes: $SCWS_DIR])
+ 
+   # Etc directory
+   if test "$SCWS_DIR" = "/usr"; then
+ 	SCWS_ETCDIR="/etc"
+   else
+ 	SCWS_ETCDIR="$SCWS_DIR/etc"
+   fi
+ 
+   # Check scws library
+   AC_CHECK_LIB(scws, scws_new, [
+ 	LIBS="$LIBS -L$SCWS_DIR/lib -lscws"
+ 	XAPIAN_LDFLAGS="$XAPIAN_LDFLAGS -L$SCWS_DIR/lib -lscws"
+ 	CPPFLAGS="$CPPFLAGS -I$SCWS_DIR/include"
+ 	AC_DEFINE(HAVE_SCWS, 1, [Define to 1 if you want to use scws as default tokenizer])
+ 	AC_DEFINE_UNQUOTED(SCWS_ETCDIR, "$SCWS_ETCDIR", [Resources directory of scws to load dictionary and rules])
+   ],[
+ 	AC_MSG_ERROR([scws_new() NOT found in libscws, please check it first.])	
+   ],[
+ 	-L$SCWS_DIR/lib
+   ])
+ fi
+ 
  dnl ******************************
  dnl * Set special compiler flags *
  dnl ******************************
*** xapian-core-1.3.0_svn16982/include/xapian/queryparser.h	2012-10-13 17:31:04.000000000 +0800
--- xapian-core-scws-1.3.0_svn16982/include/xapian/queryparser.h	2012-12-28 12:44:47.000000000 +0800
***************
*** 574,579 ****
--- 574,606 ----
       */
      void set_max_wildcard_expansion(Xapian::termcount limit);
  
+ #if 1	/* HAVE_SCWS */
+     /** Load scws dict and rule (hightman.070706)
+      *
+      *  @param fpath    The directory of dict and rule file 
+      *  @param xmem     Whether to load whole dict into memory (default to false)
+      *  @param multi    Options of scws  multi set (int 0~15)
+      */
+     void load_scws(const char *fpath, bool xmem = false, int multi = 0);
+ 
+     /** Specify the scws handle (hightman.121219)
+      *
+      *  Note: this will free exists scws handle automatically
+      *
+      *  @param scws     Type of scws_t defined in scws.h
+      */
+     void set_scws(void *scws);
+ 
+     /** Get the scws handle (hightman.121228)
+      *
+      *  @return	returns scws handler, cast type to scws_t before using it
+      */
+     void *get_scws();
+ 
+     /** Clear parsed query data (hightman.121219) */
+     void clear();
+ #endif
+ 
      /** Parse a query.
       *
       *  @param query_string  A free-text query as entered by a user
*** xapian-core-1.3.0_svn16982/include/xapian/termgenerator.h	2012-07-19 13:51:02.000000000 +0800
--- xapian-core-scws-1.3.0_svn16982/include/xapian/termgenerator.h	2012-12-28 12:48:03.000000000 +0800
***************
*** 91,96 ****
--- 91,120 ----
      /// Stemming strategies, for use with set_stemming_strategy().
      typedef enum { STEM_NONE, STEM_SOME, STEM_ALL, STEM_ALL_Z } stem_strategy;
  
+ #if 1	/* HAVE_SCWS */
+     /** Load scws dict and rule (hightman.070706)
+      *
+      *  @param fpath    The directory of dict and rule file 
+      *  @param xmem     Whether to load whole dict into memory (default to false)
+      *  @param multi    Options of scws  multi set (int 0~15)
+      */
+     void load_scws(const char *fpath, bool xmem = false, int multi = 0);
+ 
+     /** Specify the scws handle (hightman.121219)
+      *
+      *  Note: this will free exists scws handle automatically
+      *
+      *  @param scws     Type of scws_t defined in scws.h
+      */
+     void set_scws(void *scws);
+ 
+     /** Get the scws handle (hightman.121228)
+      *
+      *  @return	returns scws handler, cast type to scws_t before using it
+      */
+     void *get_scws();
+ #endif
+ 
      /** Set flags.
       *
       *  The new value of flags is: (flags & mask) ^ toggle
*** xapian-core-1.3.0_svn16982/queryparser/queryparser_internal.h	2012-07-24 11:51:20.000000000 +0800
--- xapian-core-scws-1.3.0_svn16982/queryparser/queryparser_internal.h	2012-12-28 12:42:13.000000000 +0800
***************
*** 29,34 ****
--- 29,39 ----
  #include <xapian/queryparser.h>
  #include <xapian/stem.h>
  
+ /// hightman.20070701: use scws as default tokenizer
+ #ifdef HAVE_SCWS
+ #include <scws/scws.h>
+ #endif
+ 
  #include <list>
  #include <map>
  
***************
*** 72,77 ****
--- 77,88 ----
      Stem stemmer;
      stem_strategy stem_action;
      const Stopper * stopper;
+ #ifdef HAVE_SCWS
+     scws_t scws;
+     scws_res_t rptr, rcur;
+     const char *qptr;
+     int last_off;
+ #endif
      Query::op default_op;
      const char * errmsg;
      Database db;
***************
*** 100,106 ****
--- 111,124 ----
  
    public:
      Internal() : stem_action(STEM_SOME), stopper(NULL),
+ #ifdef HAVE_SCWS
+ 	scws(NULL), rptr(NULL), rcur(NULL),
+ #endif
  	default_op(Query::OP_OR), errmsg(NULL), max_wildcard_expansion(0) { }
+ #ifdef HAVE_SCWS
+     ~Internal();
+     void load_scws(const char *fpath, bool xmem, int multi);
+ #endif
  
      Query parse_query(const string & query_string, unsigned int flags, const string & default_prefix);
  };
*** xapian-core-1.3.0_svn16982/queryparser/termgenerator_internal.h	2012-07-19 13:51:02.000000000 +0800
--- xapian-core-scws-1.3.0_svn16982/queryparser/termgenerator_internal.h	2012-12-28 12:42:13.000000000 +0800
***************
*** 26,31 ****
--- 26,35 ----
  #include <xapian/document.h>
  #include <xapian/termgenerator.h>
  #include <xapian/stem.h>
+ /// hightman.20070701: use scws as default tokenizer
+ #ifdef HAVE_SCWS
+ #include <scws/scws.h>
+ #endif
  
  namespace Xapian {
  
***************
*** 38,50 ****
--- 42,64 ----
      const Stopper * stopper;
      Document doc;
      termcount termpos;
+ #ifdef HAVE_SCWS
+     scws_t scws;
+ #endif
      TermGenerator::flags flags;
      unsigned max_word_length;
      WritableDatabase db;
  
    public:
      Internal() : strategy(STEM_SOME), stopper(NULL), termpos(0),
+ #ifdef HAVE_SCWS
+ 	scws(NULL),
+ #endif
  	flags(TermGenerator::flags(0)), max_word_length(64) { }
+ #ifdef HAVE_SCWS
+     ~Internal();
+     void load_scws(const char *fpath, bool xmem, int multi);
+ #endif
      void index_text(Utf8Iterator itor,
  		    termcount weight,
  		    const std::string & prefix,
*** xapian-core-1.3.0_svn16982/queryparser/queryparser.cc	2012-07-24 11:51:20.000000000 +0800
--- xapian-core-scws-1.3.0_svn16982/queryparser/queryparser.cc	2012-12-28 12:48:51.000000000 +0800
***************
*** 138,143 ****
--- 138,186 ----
      internal->max_wildcard_expansion = max;
  }
  
+ #if 1	/* HAVE_SCWS */
+ void
+ QueryParser::load_scws(const char *fpath, bool xmem, int multi)
+ {
+ #ifdef HAVE_SCWS
+     internal->load_scws(fpath, xmem, multi);
+ #endif
+ }
+ 
+ void
+ QueryParser::set_scws(void *scws)
+ {
+ #ifdef HAVE_SCWS
+     if (internal->scws != NULL)
+     	scws_free(internal->scws);
+     internal->scws = (scws_t) scws;
+ #endif
+ }
+ 
+ void *
+ QueryParser::get_scws()
+ {
+ #ifdef HAVE_SCWS
+     if (internal->scws == NULL)
+ 	internal->load_scws(NULL, false, 0);
+     return (void *) internal->scws;
+ #else
+     return NULL;
+ #endif
+ }
+ 
+ void
+ QueryParser::clear()
+ {
+     internal->field_map.clear();
+     internal->valrangeprocs.clear();
+     internal->stoplist.clear();
+     internal->unstem.clear();
+     internal->errmsg = NULL;
+     internal->corrected_query.resize(0);
+ }
+ #endif
+ 
  Query
  QueryParser::parse_query(const string &query_string, unsigned flags,
  			 const string &default_prefix)
*** xapian-core-1.3.0_svn16982/queryparser/queryparser_internal.cc	2012-12-27 14:13:19.000000000 +0800
--- xapian-core-scws-1.3.0_svn16982/queryparser/queryparser_internal.cc	2012-12-28 12:42:13.000000000 +0800
***************
*** 179,184 ****
--- 179,187 ----
      string unstemmed;
      QueryParser::stem_strategy stem;
      termpos pos;
+ #ifdef HAVE_SCWS
+     vector<string> multi;
+ #endif
  
      Term(const string &name_, termpos pos_) : name(name_), stem(QueryParser::STEM_NONE), pos(pos_) { }
      Term(const string &name_) : name(name_), stem(QueryParser::STEM_NONE), pos(0) { }
***************
*** 380,389 ****
--- 383,397 ----
      for (piter = prefixes.begin(); piter != prefixes.end(); ++piter) {
  	// First try the unstemmed term:
  	string term;
+ 	/* hightman.111231: Synonym optimization　*/
+ #ifdef HAVE_SCWS
+ 	termpos mpos = pos + 77;
+ #else
  	if (!piter->empty()) {
  	    term += *piter;
  	    if (prefix_needs_colon(*piter, name[0])) term += ':';
  	}
+ #endif
  	term += name;
  
  	Xapian::Database db = state->get_database();
***************
*** 392,408 ****
--- 400,430 ----
  	if (syn == end && stem != QueryParser::STEM_NONE) {
  	    // If that has no synonyms, try the stemmed form:
  	    term = 'Z';
+ #ifndef HAVE_SCWS
  	    if (!piter->empty()) {
  		term += *piter;
  		if (prefix_needs_colon(*piter, name[0])) term += ':';
  	    }
+ #endif
  	    term += state->stem_term(name);
  	    syn = db.synonyms_begin(term);
  	    end = db.synonyms_end(term);
  	}
+ #ifdef HAVE_SCWS
+ 	while (syn != end) {
+ 	    string sterm = *syn;
+ 	    if (!piter->empty()) {
+ 	    	if (sterm[0] == 'Z') sterm = "Z" + *piter + sterm.substr(1);
+ 	    	else sterm = *piter + sterm;
+ 	    }
+ 	    q = Query(Query::OP_SYNONYM, q, Query(sterm, 1, mpos++));
+ 	    ++syn;
+ 	}
+ #else
  	q = Query(q.OP_SYNONYM,
  		  SynonymIterator(syn, pos, &q),
  		  SynonymIterator(end));
+ #endif
      }
      return q;
  }
***************
*** 525,530 ****
--- 547,581 ----
      vector<Query> prefix_cjk;
      const list<string> & prefixes = field_info->prefixes;
      list<string>::const_iterator piter;
+ /* hightman.20111223: used CJKTERM for multi segment */
+ #ifdef HAVE_SCWS
+     for (piter = prefixes.begin(); piter != prefixes.end(); ++piter) {
+ 	Query org = Query(*piter + name, 1, pos);
+ 	termpos mpos = pos + 88;
+ 
+ 	/* hightman.20120104: get synonyms */
+ 	if (state->flags & QueryParser::FLAG_AUTO_SYNONYMS) {
+ 	    Xapian::Database db = state->get_database();
+ 	    Xapian::TermIterator syn = db.synonyms_begin(name);
+ 	    Xapian::TermIterator end = db.synonyms_end(name);
+ 	    while (syn != end) {
+ 		org = Query(Query::OP_SYNONYM, org, Query(*piter + *syn, 1, mpos++));
+ 		++syn;
+ 	    }
+ 	}
+ 	if (!multi.empty()) {
+ 	    vector<string>::const_iterator mi;
+ 	    vector<Query> multi_cjk;
+ 	    for (mi = multi.begin(); mi != multi.end(); ++mi) {
+ 		// hightman: force to sort behind for get_terms()
+ 		multi_cjk.push_back(Query(*piter + *mi, 1, mpos++));
+ 	    }
+ 	    Query syn = Query(state->default_op(), multi_cjk.begin(), multi_cjk.end());
+ 	    org = Query(Query::OP_SYNONYM, org, syn);
+ 	}
+ 	prefix_cjk.push_back(org);
+     }
+ #else
      for (CJKTokenIterator tk(name); tk != CJKTokenIterator(); ++tk) {
  	for (piter = prefixes.begin(); piter != prefixes.end(); ++piter) {
  	    string cjk = *piter;
***************
*** 532,537 ****
--- 583,589 ----
  	    prefix_cjk.push_back(Query(cjk, 1, pos));
  	}
      }
+ #endif	/* HAVE_SCWS */
      Query * q = new Query(Query::OP_AND, prefix_cjk.begin(), prefix_cjk.end());
      delete this;
      return q;
***************
*** 663,674 ****
--- 715,792 ----
     }
  }
  
+ /// hightman.20110701: load scws
+ #ifdef HAVE_SCWS
+ QueryParser::Internal::~Internal()
+ {
+     if (rptr != NULL) {
+ 	scws_free_result(rptr);
+ 	rptr = NULL;
+     }
+     if (scws != NULL) {
+ 	scws_free(scws);
+ 	scws = NULL;
+     }
+ }
+ 
+ void
+ QueryParser::Internal::load_scws(const char *fpath, bool xmem, int multi)
+ {
+     string temp;
+     if (scws == NULL) {
+ 	scws = scws_new();
+ 	scws_set_charset(scws, "utf8");
+ 	scws_set_ignore(scws, SCWS_NA);
+ 	scws_set_duality(scws, SCWS_YEA);
+     }
+     // default dict & rule
+     temp = string(fpath ? fpath : SCWS_ETCDIR) + string("/rules.utf8.ini");
+     scws_set_rule(scws, temp.data());
+     temp = string(fpath ? fpath : SCWS_ETCDIR) + string("/dict.utf8.xdb");
+     scws_set_dict(scws, temp.data(), xmem == true ? SCWS_XDICT_MEM : SCWS_XDICT_XDB);
+     /* hightman.20111209: custom dict support */
+     temp = string(fpath ? fpath : SCWS_ETCDIR) + string("/dict_user.txt");
+     scws_add_dict(scws, temp.data(), SCWS_XDICT_TXT);
+     // multi options
+     if (multi >= 0 && multi < 0x10)
+ 	scws_set_multi(scws, (multi<<12));
+ }
+ #endif	/* HAVE_SCWS */
+ 
  string
  QueryParser::Internal::parse_term(Utf8Iterator &it, const Utf8Iterator &end,
  				  bool cjk_ngram, bool & is_cjk_term,
  				  bool &was_acronym)
  {
      string term;
+ #ifdef HAVE_SCWS
+     int off = it.raw() - qptr;
+     while (rcur && (off > rcur->off)) {
+ 	rcur = rcur->next;
+     }
+     was_acronym = false;
+     if (rcur == NULL) { 
+ 	it = end;
+ 	term.resize(0);
+     } else {
+ 	// sometimes, auto_duality + word-end single word char will be repeated
+ 	// 说明几句 => 说明/几/几句
+ 	if (rcur->next && rcur->next->off == rcur->off && rcur->next->len > rcur->len)
+ 	    rcur = rcur->next;
+ 
+ 	term.append(qptr + rcur->off, rcur->len);
+ 	was_acronym = (rcur->attr[0] == 'n' && rcur->attr[1] == 'z') ? true : false;
+ 	is_cjk_term = CJK::codepoint_is_cjk(*it);
+ 	last_off = off = rcur->off + rcur->len;
+ 	rcur = rcur->next;
+ 
+ 	// sometimes, auto duality or multisegment
+ 	// 几句说搞笑 => 几句/句说/搞笑
+ 	if (rcur && off > rcur->off && (rcur->off + rcur->len) > off)
+ 	    off = rcur->off;
+ 	while ((it.raw() - qptr) < off) it++;
+     }
+ #else	/* HAVE_SCWS */
      // Look for initials separated by '.' (e.g. P.T.O., U.N.C.L.E).
      // Don't worry if there's a trailing '.' or not.
      if (U_isupper(*it)) {
***************
*** 753,758 ****
--- 871,877 ----
  	    }
  	}
      }
+ #endif	/* HAVE_SCWS */
      return term;
  }
  
***************
*** 804,809 ****
--- 923,953 ----
  
      ParserHandler pParser(ParseAlloc());
  
+ #ifdef HAVE_SCWS
+     /// Pre segmentation use scws
+     scws_res_t res;
+ 
+     if (scws == NULL)
+ 	load_scws(NULL, false, 0);
+     if (rptr != NULL) {
+ 	scws_free_result(rptr);
+ 	rptr = NULL;
+     }
+     qptr = qs.data();
+     scws_send_text(scws, qptr, qs.size());
+     while ((res = scws_get_result(scws)) != NULL) {
+ 	if (rptr == NULL) { 
+ 	    rcur = rptr = res;
+         } else { 
+ 	    rcur->next = res;
+         }
+ 	while (rcur->next != NULL) { 
+ 	    rcur = rcur->next;
+ 	}
+     }
+     rcur = rptr;
+ #endif	/* HAVE_SCWS */
+ 
      unsigned newprev = ' ';
  main_lex_loop:
      enum {
***************
*** 1212,1217 ****
--- 1356,1366 ----
  		if (!stemmer.internal.get()) {
  		    // No stemmer is set.
  		    stem_term = STEM_NONE;
+ #ifdef HAVE_SCWS
+ 		} else if (is_cjk_term) {
+ 		    // Don't stem CJK terms.
+ 		    stem_term = STEM_NONE;
+ #endif
  		} else if (stem_term == STEM_SOME) {
  		    if (!should_stem(unstemmed_term) ||
  			(it != end && is_stem_preventer(*it))) {
***************
*** 1225,1230 ****
--- 1374,1390 ----
  				       unstemmed_term, stem_term, term_pos++);
  
  	    if (is_cjk_term) {
+ #ifdef HAVE_SCWS
+ 		/* multi scws handler */
+ 		term_obj->multi.clear();
+ 		while (rcur && (rcur->off + rcur->len) <= last_off) {
+ 			if (rcur->len > 3)
+ 				term_obj->multi.push_back(string(qptr + rcur->off, rcur->len));
+ 		    rcur = rcur->next;
+ 		}
+ 		if (mode == IN_GROUP || mode == IN_GROUP2)
+ 		    mode = DEFAULT;
+ #endif
  		Parse(pParser, CJKTERM, term_obj, &state);
  		if (it == end) break;
  		continue;
***************
*** 1355,1360 ****
--- 1515,1527 ----
  	}
      }
  done:
+ #ifdef HAVE_SCWS
+     /// Free all segmented terms/words
+     if (rptr != NULL) {
+ 	scws_free_result(rptr);
+ 	rptr = NULL;
+     }
+ #endif
      if (!state.error) {
  	// Implicitly close any unclosed quotes.
  	if (mode == IN_QUOTES || mode == IN_PREFIXED_QUOTES)
***************
*** 1712,1717 ****
--- 1879,1889 ----
  void
  Term::as_positional_cjk_term(Terms * terms) const
  {
+ #ifdef HAVE_SCWS
+     // Add SCWS term only
+     Term * c = new Term(state, name, field_info, unstemmed, stem, pos);
+     terms->add_positional_term(c);
+ #else
      // Add each individual CJK character to the phrase.
      string t;
      for (Utf8Iterator it(name); it != Utf8Iterator(); ++it) {
***************
*** 1720,1725 ****
--- 1892,1898 ----
  	terms->add_positional_term(c);
  	t.resize(0);
      }
+ #endif	/* HAVE_SCWS */
  
      // FIXME: we want to add the n-grams as filters too for efficiency.
  
*** xapian-core-1.3.0_svn16982/queryparser/termgenerator.cc	2012-11-20 05:31:02.000000000 +0800
--- xapian-core-scws-1.3.0_svn16982/queryparser/termgenerator.cc	2012-12-28 12:49:44.000000000 +0800
***************
*** 74,79 ****
--- 74,111 ----
      internal->db = db;
  }
  
+ #if 1	/* HAVE_SCWS */
+ void
+ TermGenerator::load_scws(const char *fpath, bool xmem, int multi)
+ {
+ #ifdef HAVE_SCWS
+     internal->load_scws(fpath, xmem, multi);
+ #endif
+ }
+ 
+ void
+ TermGenerator::set_scws(void *scws)
+ {
+ #ifdef HAVE_SCWS
+     if (internal->scws != NULL)
+ 	scws_free(internal->scws);
+     internal->scws = (scws_t) scws;
+ #endif
+ }
+ 
+ void *
+ TermGenerator::get_scws()
+ {
+ #ifdef HAVE_SCWS
+     if (internal->scws == NULL)
+ 	internal->load_scws(NULL, false, 0);
+     return (void *) internal->scws;
+ #else
+     return NULL;
+ #endif
+ }
+ #endif
+ 
  TermGenerator::flags
  TermGenerator::set_flags(flags toggle, flags mask)
  {
*** xapian-core-1.3.0_svn16982/queryparser/termgenerator_internal.cc	2012-07-19 13:51:02.000000000 +0800
--- xapian-core-scws-1.3.0_svn16982/queryparser/termgenerator_internal.cc	2012-12-28 12:42:13.000000000 +0800
***************
*** 117,122 ****
--- 117,156 ----
  #define STOPWORDS_IGNORE 1
  #define STOPWORDS_INDEX_UNSTEMMED_ONLY 2
  
+ /// hightman.20070701: load scws
+ #ifdef HAVE_SCWS
+ TermGenerator::Internal::~Internal()
+ {
+     if (scws != NULL) {
+ 	scws_free(scws);
+ 	scws = NULL;
+     }
+ }
+ 
+ void 
+ TermGenerator::Internal::load_scws(const char *fpath, bool xmem, int multi)
+ {
+     string temp;
+     if (scws == NULL) {
+ 	scws = scws_new();
+ 	scws_set_charset(scws, "utf8");
+ 	scws_set_ignore(scws, SCWS_NA);
+ 	scws_set_duality(scws, SCWS_YEA);
+     }
+     // default dict & rule
+     temp = string(fpath ? fpath : SCWS_ETCDIR) + string("/rules.utf8.ini");
+     scws_set_rule(scws, temp.data());
+     temp = string(fpath ? fpath : SCWS_ETCDIR) + string("/dict.utf8.xdb");
+     scws_set_dict(scws, temp.data(), xmem == true ? SCWS_XDICT_MEM : SCWS_XDICT_XDB);
+     /* hightman.20111209: custom dict support */
+     temp = string(fpath ? fpath : SCWS_ETCDIR) + string("/dict_user.txt");
+     scws_add_dict(scws, temp.data(), SCWS_XDICT_TXT);
+     // multi options
+     if (multi >= 0 && multi < 0x10)
+ 	scws_set_multi(scws, (multi<<12));
+ }
+ #endif
+ 
  void
  TermGenerator::Internal::index_text(Utf8Iterator itor, termcount wdf_inc,
  				    const string & prefix, bool with_positions)
***************
*** 127,132 ****
--- 161,198 ----
  
      if (!stopper) stop_mode = STOPWORDS_NONE;
  
+ #ifdef HAVE_SCWS
+     int last_endpos = 0, last_off = 0;
+     scws_res_t res, cur;
+     Utf8Iterator iterm;
+     const char *text = itor.raw();
+ 
+     if (scws == NULL)
+     	load_scws(NULL, false, 0);
+     scws_send_text(scws, text, itor.left());
+     while ((res = cur = scws_get_result(scws)) != NULL) { while (cur != NULL) {
+ 	string term;
+ 
+ 	iterm.assign(text + cur->off, cur->len);
+ 	if (!Unicode::is_wordchar(*iterm)) {
+ 	    cur = cur->next;
+ 	    continue;
+ 	}
+ 	term = Unicode::tolower(string(text + cur->off, cur->len));
+ 	if (with_positions) {
+ 	    /// for part word(short, duality)
+ 	    if ((cur->off + cur->len) <= last_endpos)
+ 		--termpos;
+ 	    else {
+ 		/// for dualities' first single word
+ 		if (cur->off == last_off)
+ 		    --termpos;
+ 		last_endpos = cur->off + cur->len;
+ 	    }
+ 	}
+ 	last_off = cur->off;
+ 	cur = cur->next;
+ #else
      while (true) {
  	// Advance to the start of the next term.
  	unsigned ch;
***************
*** 262,267 ****
--- 328,334 ----
  	}
  
  endofterm:
+ #endif	/* HAVE_SCWS */
  	if (term.size() > max_word_length) continue;
  
  	if (stop_mode == STOPWORDS_IGNORE && (*stopper)(term)) continue;
***************
*** 274,279 ****
--- 341,350 ----
  		doc.add_term(prefix + term, wdf_inc);
  	    }
  	}
+ #ifdef HAVE_SCWS
+ 	/// hightman: Term start with CJK character needn't spell & stem
+ 	if (CJK::codepoint_is_cjk(*iterm)) continue;
+ #endif
  	if ((flags & FLAG_SPELLING) && prefix.empty()) db.add_spelling(term);
  
  	if (strategy == TermGenerator::STEM_NONE ||
***************
*** 302,307 ****
--- 373,381 ----
  	    doc.add_term(stem, wdf_inc);
  	}
      }
+ #ifdef HAVE_SCWS
+     scws_free_result(res); }
+ #endif
  }
  
  }
