require 'inflector.rb'

class String
  include Inflector
  
  @@sql_regular_expressions = [ Regexp.new( '"' ), Regexp.new( "'" ),
    Regexp.new( '/' ), /\)/, /;/, /--/, /\balter\b/i, /\banalyze\b/i,
    /\baverage\b/i, /\bbackup\b/i, /\bbinlog\b/i, /\bcache\b/i,
    /\bcase\b/i, /\bchange\b/i, /\bcharacter\b/i, /\bcheck\b/i,
    /\bcollation\b/i, /\bcolumns\b/i, /\bcommit\b/i, /\bcount\b/i,
    /\bcreate\b/i, /\bdatabase\b/i, /\bdelete\b/i, /\bdescribe\b/i,
    /\bdo\b/i, /\bdrop\b/i, /\bengines\b/i, /\berrors\b/i,
    /\bexplain\b/i, /\bevents\b/i, /\bflush\b/i, /\bfrom\b/i,
    /\bgrant\b/i, /\bgroup\b/i, /\bhandler\b/i, /\bif\b/i,
    /\bindex\b/i, /\binnodb\b/i, /\binsert\b/i, /\bjoin\b/i,
    /\bkill\b/i, /\bload\b/i, /\block\b/i, /\blogs\b/i, /\bmaster\b/i,
    /\boptimize\b/i, /\bpurge\b/i, /\brename\b/i, /\brepair\b/i,
    /\breplace\b/i, /\breset\b/i, /\brestore\b/i, /\brevoke\b/i,
    /\brollback\b/i, /\bsavepoint\b/i, /\bselect\b/i, /\bset\b/i,
    /\bshow\b/i, /\bslave\b/i, /\bsql_log_bin\b/i, /\bstart\b/i,
    /\btable\b/i, /\btransaction\b/i, /\btruncate\b/i,
    /\bunion\b/i, /\bunlock\b/i, /\buse\b/i, /\bvariables\b/i,
    /\bview\b/i, /\bwarning\b/i, /\bwhere\b/i
    #/null/i,   # removed so that we can explicity store NULL in database
    #/password/i # prevents using password field in person table
  ]

  def blank?
    self == ''
  end

  # As seen on http://infovore.org/archives/2006/08/11/writing-your-own-camelizer-in-ruby/
  def camelize
    to_s.gsub( /\/(.?)/ ) do
      "::" + $1.upcase
    end.gsub( /(^|_)(.)/ ) do
      $2.upcase
    end
  end

  # Want to iterate over each regular expression, comparing
  # tainted_string to each.
  def contains_sql?
    @@sql_regular_expressions.each do |regex| 
      return true if regex =~ self.to_s
    end

    false
  end
  
  def contains_no_sql?
    !contains_sql?
  end

  def pluralize
    Inflector.pluralize( self )
  end

  def singularize
    Inflector.singularize( self )
  end

  # Returns a class associated with the string
  def tablify
    table_name = gsub( /_id$/, '' ).split( '_' ).collect do |word|
      word.singularize
    end.join( '_' ).camelize

    Object.module_eval( table_name )
  end
end
