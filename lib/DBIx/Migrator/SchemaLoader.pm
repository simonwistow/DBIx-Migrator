package DBIx::Migrator::SchemaLoader;
use strict;

sub schema {
  my $class = shift;
  my $table = shift;
  my $dbh   = shift;

  my $db_type = $dbh->{'Driver'}{'Name'} or die 'Cannot determine DBI type';
  my $sub     = lc($db_type);
  die "Can't load from $db_type at the moment" unless $class->can($sub);
  $class->$sub($table, $dbh);
}

sub mysql {
  my $class = shift;
  my $table = shift;
  my $dbh   = shift;

  local $dbh->{RaiseError} = 0;
  local $dbh->{PrintError} = 0;  
  my $spec  = eval { $dbh->selectrow_arrayref("SHOW CREATE TABLE $table")->[1] };
  return undef unless $spec;

  $spec =~ s/ ENGINE=.*$//;
  return $spec;
}

sub sqlite {
  my $class = shift;
  my $table = shift;
  my $dbh   = shift;

  my $sth   = $dbh->table_info('', '%',  $table, 'TABLE') or die $dbh->errstr;
  my $row   = $sth->fetchrow_arrayref();
  return $row ? $row->[5] : undef;
}

sub pg { 
  my $class = shift;
  my $table = shift;
  my $dbh   = shift;
  
  local $dbh->{RaiseError} = 0;
  local $dbh->{PrintError} = 0;  
  $dbh->do(q[CREATE OR REPLACE FUNCTION dbix_migrator_generate_create_table_statement(p_table_name varchar)
   RETURNS text AS
 $BODY$
 DECLARE
     v_table_ddl   text;
     column_record record;
 BEGIN
     FOR column_record IN 
         SELECT 
             b.nspname as schema_name,
             b.relname as table_name,
             a.attname as column_name,
             pg_catalog.format_type(a.atttypid, a.atttypmod) as column_type,
             CASE WHEN 
                 (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
                  FROM pg_catalog.pg_attrdef d
                  WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef) IS NOT NULL THEN
                 'DEFAULT '|| (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
                               FROM pg_catalog.pg_attrdef d
                               WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef)
             ELSE
                 ''
             END as column_default_value,
             CASE WHEN a.attnotnull = true THEN 
                 'NOT NULL'
             ELSE
                 'NULL'
             END as column_not_null,
             a.attnum as attnum,
             e.max_attnum as max_attnum
         FROM 
             pg_catalog.pg_attribute a
             INNER JOIN 
              (SELECT c.oid,
                 n.nspname,
                 c.relname
               FROM pg_catalog.pg_class c
                    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
               WHERE c.relname ~ ('^('||p_table_name||')$')
                 AND pg_catalog.pg_table_is_visible(c.oid)
               ORDER BY 2, 3) b
             ON a.attrelid = b.oid
             INNER JOIN 
              (SELECT 
                   a.attrelid,
                   max(a.attnum) as max_attnum
               FROM pg_catalog.pg_attribute a
               WHERE a.attnum > 0 
                 AND NOT a.attisdropped
               GROUP BY a.attrelid) e
             ON a.attrelid=e.attrelid
         WHERE a.attnum > 0 
           AND NOT a.attisdropped
         ORDER BY a.attnum
     LOOP
         IF column_record.attnum = 1 THEN
             v_table_ddl:='CREATE TABLE '||column_record.schema_name||'.'||column_record.table_name||' (';
         ELSE
             v_table_ddl:=v_table_ddl||',';
         END IF;
 
         IF column_record.attnum <= column_record.max_attnum THEN
             v_table_ddl:=v_table_ddl||chr(10)||
                      '    '||column_record.column_name||' '||column_record.column_type||' '||column_record.column_default_value||' '||column_record.column_not_null;
         END IF;
     END LOOP;
 
     v_table_ddl:=v_table_ddl||');';
     RETURN v_table_ddl;
 END;
 $BODY$
   LANGUAGE 'plpgsql' COST 100.0 SECURITY INVOKER]);
   my $spec  = eval { $dbh->selectrow_arrayref("SELECT dbix_migrator_generate_create_table_statement(?)", {}, $table)->[0] };
   $dbh->do("DROP FUNCTION dbix_migrator_generate_create_table_statement(p_table_name varchar)");
   return $spec;
 }
# sub odbc   { }
# sub oracle { }
# sub sybase { }
# sub db2    { }
1;