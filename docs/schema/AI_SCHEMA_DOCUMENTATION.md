# PostgreSQL AI Schema Documentation

**Database:** rag_db
**Schema:** ai
**Generated:** 2025-11-10 13:10:12

---

## Table of Contents

1. [Overview](#overview)
2. [Tables](#tables)
3. [Views](#views)
4. [Functions](#functions)
5. [Custom Types](#custom-types)
6. [Sequences](#sequences)
7. [Usage Examples](#usage-examples)

---

## Overview

The `ai` schema is created by the **pgai** extension from Timescale. 
It provides a complete infrastructure for managing vector embeddings 
and integrating large language models (LLMs) directly into PostgreSQL.

### Schema Statistics

- **Tables:** 90
- **Views:** 3
- **Functions:** 192
- **Custom Types:** 93
- **Sequences:** 3

---

## Tables

The ai schema contains catalog tables for managing vectorizers 
and dynamically created queue tables for each vectorizer.

### Core Tables (12)

#### `ai._secret_permissions`

**Estimated Rows:** -1
**Total Size:** 32 kB

#### `ai._vectorizer_errors`

**Estimated Rows:** -1
**Total Size:** 32 kB

#### `ai.feature_flag`

**Estimated Rows:** -1
**Total Size:** 16 kB

#### `ai.migration`

**Estimated Rows:** -1
**Total Size:** 48 kB

#### `ai.pgai_lib_feature_flag`

**Estimated Rows:** -1
**Total Size:** 16 kB

#### `ai.pgai_lib_migration`

**Estimated Rows:** -1
**Total Size:** 72 kB

#### `ai.pgai_lib_version`

**Estimated Rows:** -1
**Total Size:** 32 kB

#### `ai.semantic_catalog`

**Estimated Rows:** -1
**Total Size:** 24 kB

#### `ai.semantic_catalog_embedding`

**Estimated Rows:** -1
**Total Size:** 24 kB

#### `ai.vectorizer`

**Estimated Rows:** -1
**Total Size:** 144 kB

#### `ai.vectorizer_worker_process`

**Estimated Rows:** 4
**Total Size:** 296 kB

#### `ai.vectorizer_worker_progress`

**Estimated Rows:** 26
**Total Size:** 64 kB

### Vectorizer Queue Tables (78)

Each vectorizer creates a dedicated queue table named `_vectorizer_q_<id>` 
to track items pending processing. These tables have a consistent structure:

- `id` - Integer identifier
- `queued_at` - Timestamp when queued
- `loading_retries` - Number of retry attempts
- `loading_retry_after` - Timestamp for next retry

**Total Queue Tables:** 78

---

## Views

### `ai.secret_permissions`

**Definition:**

```sql
SELECT name,
    role
   FROM ai._secret_permissions
  WHERE to_regrole(role) IS NOT NULL AND pg_has_role(CURRENT_USER, role::name, 'member'::text);
```

### `ai.vectorizer_errors`

**Definition:**

```sql
SELECT ve.id,
    ve.message,
    ve.details,
    ve.recorded,
    v.name
   FROM ai._vectorizer_errors ve
     LEFT JOIN ai.vectorizer v ON ve.id = v.id;
```

### `ai.vectorizer_status`

**Definition:**

```sql
SELECT id,
    name,
    format('%I.%I'::text, source_schema, source_table) AS source_table,
        CASE
            WHEN ((config -> 'destination'::text) ->> 'implementation'::text) = 'table'::text THEN format('%I.%I'::text, (config -> 'destination'::text) ->> 'target_schema'::text, (config -> 'destination'::text) ->> 'target_table'::text)
            ELSE NULL::text
        END AS target_table,
        CASE
            WHEN ((config -> 'destination'::text) ->> 'implementation'::text) = 'table'::text THEN format('%I.%I'::text, (config -> 'destination'::text) ->> 'view_schema'::text, (config -> 'destination'::text) ->> 'view_name'::text)
            ELSE NULL::text
        END AS view,
        CASE
            WHEN ((config -> 'destination'::text) ->> 'implementation'::text) = 'column'::text THEN format('%I'::text, (config -> 'destination'::text) ->> 'embedding_column'::text)
            ELSE 'embedding'::text
        END AS embedding_column,
        CASE
            WHEN queue_table IS NOT NULL AND has_table_privilege(CURRENT_USER, format('%I.%I'::text, queue_schema, queue_table), 'select'::text) THEN ai.vectorizer_queue_pending(id)
            ELSE NULL::bigint
        END AS pending_items,
    disabled
   FROM ai.vectorizer v;
```

---

## Functions

The ai schema provides extensive functions for managing vectorizers 
and configuring embedding providers.

### Vectorizer Management (3 functions)

#### `create_vectorizer(source regclass, name text DEFAULT NULL::text, destination jsonb DEFAULT ai.destination_table(), loading jsonb DEFAULT NULL::jsonb, parsing jsonb DEFAULT ai.parsing_auto(), embedding jsonb DEFAULT NULL::jsonb, chunking jsonb DEFAULT ai.chunking_recursive_character_text_splitter(), indexing jsonb DEFAULT ai.indexing_default(), formatting jsonb DEFAULT ai.formatting_python_template(), scheduling jsonb DEFAULT ai.scheduling_default(), processing jsonb DEFAULT ai.processing_default(), queue_schema name DEFAULT NULL::name, queue_table name DEFAULT NULL::name, grant_to name[] DEFAULT ai.grant_to(), enqueue_existing boolean DEFAULT true, if_not_exists boolean DEFAULT false)`

**Returns:** `integer`

**Language:** plpgsql
**Volatility:** volatile

<details>
<summary>View Definition</summary>

```sql
CREATE OR REPLACE FUNCTION ai.create_vectorizer(source regclass, name text DEFAULT NULL::text, destination jsonb DEFAULT ai.destination_table(), loading jsonb DEFAULT NULL::jsonb, parsing jsonb DEFAULT ai.parsing_auto(), embedding jsonb DEFAULT NULL::jsonb, chunking jsonb DEFAULT ai.chunking_recursive_character_text_splitter(), indexing jsonb DEFAULT ai.indexing_default(), formatting jsonb DEFAULT ai.formatting_python_template(), scheduling jsonb DEFAULT ai.scheduling_default(), processing jsonb DEFAULT ai.processing_default(), queue_schema name DEFAULT NULL::name, queue_table name DEFAULT NULL::name, grant_to name[] DEFAULT ai.grant_to(), enqueue_existing boolean DEFAULT true, if_not_exists boolean DEFAULT false)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
declare
    _missing_roles pg_catalog.name[];
    _source_table pg_catalog.name;
    _source_schema pg_catalog.name;
    _trigger_name pg_catalog.name;
    _is_owner pg_catalog.bool;
    _dimensions pg_catalog.int4;
    _source_pk pg_catalog.jsonb;
    _vectorizer_id pg_catalog.int4;
    _existing_vectorizer_id pg_catalog.int4;
    _sql pg_catalog.text;
    _job_id pg_catalog.int8;
    _queue_failed_table pg_catalog.name;
begin
    -- make sure all the roles listed in grant_to exist
    if grant_to is not null then
        select
          pg_catalog.array_agg(r) filter (where r operator(pg_catalog.!=) 'public' and pg_catalog.to_regrole(r) is null) -- missing
        , pg_catalog.array_agg(r) filter (where r operator(pg_catalog.=) 'public' or pg_catalog.to_regrole(r) is not null) -- real roles
        into strict
          _missing_roles
        , grant_to
        from pg_catalog.unnest(grant_to) r
        ;
        if pg_catalog.array_length(_missing_roles, 1) operator(pg_catalog.>) 0 then
            raise warning 'one or more grant_to roles do not exist: %', _missing_roles;
        end if;
    end if;

    if embedding is null then
        raise exception 'embedding configuration is required';
    end if;

    if loading is null then
        raise exception 'loading configuration is required';
    end if;

    -- get source table name and schema name
    select
      k.relname
    , n.nspname
    , pg_catalog.pg_has_role(pg_catalog.current_user(), k.relowner, 'MEMBER')
    into strict _source_table, _source_schema, _is_owner
    from pg_catalog.pg_class k
    inner join pg_catalog.pg_namespace n on (k.relnamespace operator(pg_catalog.=) n.oid)
    where k.oid operator(pg_catalog.=) source
    ;
    -- not an owner of the table, but superuser?
    if not _is_owner then
        select r.rolsuper into strict _is_owner
        from pg_catalog.pg_roles r
        where r.rolname operator(pg_catalog.=) pg_catalog.current_user()
        ;
    end if;

    if not _is_owner then
        raise exception 'only a superuser or the owner of the source table may create a vectorizer on it';
    end if;

    select (embedding operator(pg_catalog.->) 'dimensions')::pg_catalog.int4 into _dimensions;
    if _dimensions is null then
        raise exception 'dimensions argument is required';
    end if;

    -- get the source table's primary key definition
    select ai._vectorizer_source_pk(source) into strict _source_pk;
    if _source_pk is null or pg_catalog.jsonb_array_length(_source_pk) operator(pg_catalog.=) 0 then
        raise exception 'source table must have a primary key constraint';
    end if;

    _vectorizer_id = pg_catalog.nextval('ai.vectorizer_id_seq'::pg_catalog.regclass);
    _trigger_name = pg_catalog.concat('_vectorizer_src_trg_', _vectorizer_id);
    queue_schema = coalesce(queue_schema, 'ai');
    queue_table = coalesce(queue_table, pg_catalog.concat('_vectorizer_q_', _vectorizer_id));
    _queue_failed_table = pg_catalog.concat('_vectorizer_q_failed_', _vectorizer_id);

    -- make sure queue table name is available
    if pg_catalog.to_regclass(pg_catalog.format('%I.%I', queue_schema, queue_table)) is not null then
        raise exception 'an object named %.% already exists. specify an alternate queue_table explicitly', queue_schema, queue_table
        using errcode = 'duplicate_object';
    end if;

    -- validate the loading config
    perform ai._validate_loading(loading, _source_schema, _source_table);

    -- validate the parsing config
    perform ai._validate_parsing(
        parsing,
        loading,
        _source_schema,
        _source_table
    );

    -- validate the destination config
    perform ai._validate_destination(destination, chunking);

    -- validate the embedding config
    perform ai._validate_embedding(embedding);

    -- validate the chunking config
    perform ai._validate_chunking(chunking);

    -- if ai.indexing_default, resolve the default
    if indexing operator(pg_catalog.->>) 'implementation' = 'default' then
        indexing = ai._resolve_indexing_default();
    end if;

    -- validate the indexing config
    perform ai._validate_indexing(indexing);

    -- validate the formatting config
    perform ai._validate_formatting(formatting, _source_schema, _source_table);

    -- if ai.scheduling_default, resolve the default
    if scheduling operator(pg_catalog.->>) 'implementation' = 'default' then
        scheduling = ai._resolve_scheduling_default();
    end if;

    -- validate the scheduling config
    perform ai._validate_scheduling(scheduling);

    -- validate the processing config
    perform ai._validate_processing(processing);

    -- if scheduling is none then indexing must also be none
    if scheduling operator(pg_catalog.->>) 'implementation' = 'none'
    and indexing operator(pg_catalog.->>) 'implementation' != 'none' then
        raise exception 'automatic indexing is not supported without scheduling. set indexing=>ai.indexing_none() when scheduling=>ai.scheduling_none()';
    end if;

    -- evaluate the destination config
    destination = ai._evaluate_destination(destination, _source_schema, _source_table);

    if name is null then
        if destination operator(pg_catalog.->>) 'implementation' = 'table' then
            name = pg_catalog.format('%s_%s', destination operator(pg_catalog.->>) 'target_schema', destination operator(pg_catalog.->>) 'target_table');
        elseif destination operator(pg_catalog.->>) 'implementation' = 'column' then
            name = pg_catalog.format('%s_%s_%s', _source_schema, _source_table, destination operator(pg_catalog.->>) 'embedding_column');
        end if;
    end if;

    -- validate the name is available
    select id from ai.vectorizer
    where ai.vectorizer.name operator(pg_catalog.=) create_vectorizer.name
    into _existing_vectorizer_id
    ;
    if _existing_vectorizer_id is not null then
        if if_not_exists is false then
            raise exception 'a vectorizer named % already exists.', name
            using errcode = 'duplicate_object';
        end if;
        raise notice 'a vectorizer named % already exists, skipping', name;
        return _existing_vectorizer_id;
    end if;

    -- validate the destination can create objects after the if_not_exists check
    perform ai._validate_destination_can_create_objects(destination);

    -- grant select to source table
    perform ai._vectorizer_grant_to_source
    ( _source_schema
    , _source_table
    , grant_to
    );

    -- create the target table or column
    if destination operator(pg_catalog.->>) 'implementation' = 'table' then
        perform ai._vectorizer_create_destination_table
        ( _source_schema
        , _source_table
        , _source_pk
        , _dimensions
        , destination
        , grant_to
        );
    elseif destination operator(pg_catalog.->>) 'implementation' = 'column' then
        perform ai._vectorizer_create_destination_column
        ( _source_schema
        , _source_table
        , _dimensions
        , destination
        );
    else
        raise exception 'invalid implementation for destination';
    end if;

    -- create queue table
    perform ai._vectorizer_create_queue_table
    ( queue_schema
    , queue_table
    , _source_pk
    , grant_to
    );

    -- create queue failed table
    perform ai._vectorizer_create_queue_failed_table
    ( queue_schema
    , _queue_failed_table
    , _source_pk
    , grant_to
    );

    -- create trigger on source table to populate queue
    perform ai._vectorizer_create_source_trigger
    ( _trigger_name
    , queue_schema
    , queue_table
    , _source_schema
    , _source_table
    , destination operator(pg_catalog.->>) 'target_schema'
    , destination operator(pg_catalog.->>) 'target_table'
    , _source_pk
    );


    -- schedule the async ext job
    select ai._vectorizer_schedule_job
    (_vectorizer_id
    , scheduling
    ) into _job_id
    ;
    if _job_id is not null then
        scheduling = pg_catalog.jsonb_insert(scheduling, array['job_id'], pg_catalog.to_jsonb(_job_id));
    end if;

    insert into ai.vectorizer
    ( id
    , source_schema
    , source_table
    , source_pk
    , trigger_name
    , queue_schema
    , queue_table
    , queue_failed_table
    , config
    , name
    )
    values
    ( _vectorizer_id
    , _source_schema
    , _source_table
    , _source_pk
    , _trigger_name
    , queue_schema
    , queue_table
    , _queue_failed_table
    , pg_catalog.jsonb_build_object
      ( 'version', '0.12.1'
      , 'loading', loading
      , 'parsing', parsing
      , 'embedding', embedding
      , 'chunking', chunking
      , 'indexing', indexing
      , 'formatting', formatting
      , 'scheduling', scheduling
      , 'processing', processing
      , 'destination', destination
      )
    , create_vectorizer.name
    );

    -- grant select on the vectorizer table
    perform ai._vectorizer_grant_to_vectorizer(grant_to);

    -- insert into queue any existing rows from source table
    if enqueue_existing is true then
        select pg_catalog.format
        ( $sql$
        insert into %I.%I (%s)
        select %s
        from %I.%I x
        ;
        $sql$
        , queue_schema, queue_table
        , (
            select pg_catalog.string_agg(pg_catalog.format('%I', x.attname), ', ' order by x.attnum)
            from pg_catalog.jsonb_to_recordset(_source_pk) x(attnum int, attname name)
          )
        , (
            select pg_catalog.string_agg(pg_catalog.format('x.%I', x.attname), ', ' order by x.attnum)
            from pg_catalog.jsonb_to_recordset(_source_pk) x(attnum int, attname name)
          )
        , _source_schema, _source_table
        ) into strict _sql
        ;
        execute _sql;
    end if;
    return _vectorizer_id;
end
$function$

```
</details>

#### `drop_vectorizer(vectorizer_id integer, drop_all boolean DEFAULT false)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

<details>
<summary>View Definition</summary>

```sql
CREATE OR REPLACE FUNCTION ai.drop_vectorizer(vectorizer_id integer, drop_all boolean DEFAULT false)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
/* drop_vectorizer
This function does the following:
1. deletes the scheduled job if any
2. drops the trigger from the source table
3. drops the trigger function
4. drops the queue table
5. deletes the vectorizer row

UNLESS drop_all = true, it does NOT:
1. drop the target table containing the embeddings
2. drop the view joining the target and source
*/
declare
    _vec ai.vectorizer%rowtype;
    _schedule pg_catalog.jsonb;
    _job_id pg_catalog.int8;
    _trigger pg_catalog.pg_trigger%rowtype;
    _sql pg_catalog.text;
begin
    -- grab the vectorizer we need to drop
    select v.* into strict _vec
    from ai.vectorizer v
    where v.id operator(pg_catalog.=) vectorizer_id
    ;

    -- delete the scheduled job if exists
    _schedule = _vec.config operator(pg_catalog.->) 'scheduling';
    if _schedule is not null then
        case _schedule operator(pg_catalog.->>) 'implementation'
            when 'none' then -- ok
            when 'timescaledb' then
                _job_id = (_schedule operator(pg_catalog.->) 'job_id')::pg_catalog.int8;
                select pg_catalog.format
                ( $$select %I.delete_job(job_id) from timescaledb_information.jobs where job_id = %L$$
                , n.nspname
                , _job_id
                ) into _sql
                from pg_catalog.pg_extension x
                inner join pg_catalog.pg_namespace n on (x.extnamespace operator(pg_catalog.=) n.oid)
                where x.extname operator(pg_catalog.=) 'timescaledb'
                ;
                if found then
                    execute _sql;
                end if;
        end case;
    end if;

    -- try to look up the trigger so we can find the function/procedure backing the trigger
    select * into _trigger
    from pg_catalog.pg_trigger g
    inner join pg_catalog.pg_class k
    on (g.tgrelid operator(pg_catalog.=) k.oid
    and k.relname operator(pg_catalog.=) _vec.source_table)
    inner join pg_catalog.pg_namespace n
    on (k.relnamespace operator(pg_catalog.=) n.oid
    and n.nspname operator(pg_catalog.=) _vec.source_schema)
    where g.tgname operator(pg_catalog.=) _vec.trigger_name
    ;

    -- drop the trigger on the source table
    if found then
        select pg_catalog.format
        ( $sql$drop trigger %I on %I.%I$sql$
        , _trigger.tgname
        , _vec.source_schema
        , _vec.source_table
        ) into strict _sql
        ;
        execute _sql;

        select pg_catalog.format
        ( $sql$drop trigger if exists %I on %I.%I$sql$
        , format('%s_truncate', _trigger.tgname)
        , _vec.source_schema
        , _vec.source_table
        ) into _sql;
        execute _sql;

        -- drop the function/procedure backing the trigger
        select pg_catalog.format
        ( $sql$drop %s %I.%I()$sql$
        , case p.prokind when 'f' then 'function' when 'p' then 'procedure' end
        , n.nspname
        , p.proname
        ) into _sql
        from pg_catalog.pg_proc p
        inner join pg_catalog.pg_namespace n on (n.oid operator(pg_catalog.=) p.pronamespace)
        where p.oid operator(pg_catalog.=) _trigger.tgfoid
        ;
        if found then
            execute _sql;
        end if;
    else
        -- the trigger is missing. try to find the backing function by name and return type
        select pg_catalog.format
        ( $sql$drop %s %I.%I() cascade$sql$ -- cascade in case the trigger still exists somehow
        , case p.prokind when 'f' then 'function' when 'p' then 'procedure' end
        , n.nspname
        , p.proname
        ) into _sql
        from pg_catalog.pg_proc p
        inner join pg_catalog.pg_namespace n on (n.oid operator(pg_catalog.=) p.pronamespace)
        inner join pg_catalog.pg_type y on (p.prorettype operator(pg_catalog.=) y.oid)
        where n.nspname operator(pg_catalog.=) _vec.queue_schema
        and p.proname operator(pg_catalog.=) _vec.trigger_name
        and y.typname operator(pg_catalog.=) 'trigger'
        ;
        if found then
            execute _sql;
        end if;
    end if;

    -- drop the queue table if exists
    select pg_catalog.format
    ( $sql$drop table if exists %I.%I$sql$
    , _vec.queue_schema
    , _vec.queue_table
    ) into strict _sql;
    execute _sql;

    -- drop the failed queue table if exists
    select pg_catalog.format
    ( $sql$drop table if exists %I.%I$sql$
    , _vec.queue_schema
    , _vec.queue_failed_table
    ) into strict _sql;
    execute _sql;

    if drop_all and _vec.config operator(pg_catalog.->) 'destination' operator(pg_catalog.->>) 'implementation' operator(pg_catalog.=) 'table' then
        -- drop the view if exists
        select pg_catalog.format
        ( $sql$drop view if exists %I.%I$sql$
        , _vec.config operator(pg_catalog.->) 'destination' operator(pg_catalog.->>) 'view_schema'
        , _vec.config operator(pg_catalog.->) 'destination' operator(pg_catalog.->>) 'view_name'
        ) into strict _sql;
        execute _sql;

        -- drop the target table if exists
        select pg_catalog.format
        ( $sql$drop table if exists %I.%I$sql$
        , _vec.config operator(pg_catalog.->) 'destination' operator(pg_catalog.->>) 'target_schema'
        , _vec.config operator(pg_catalog.->) 'destination' operator(pg_catalog.->>) 'target_table'
        ) into strict _sql;
        execute _sql;
    end if;

    -- delete the vectorizer row
    delete from ai.vectorizer v
    where v.id operator(pg_catalog.=) vectorizer_id
    ;
end;
$function$

```
</details>

#### `drop_vectorizer(name text, drop_all boolean DEFAULT false)`

**Returns:** `void`

**Language:** sql
**Volatility:** volatile

<details>
<summary>View Definition</summary>

```sql
CREATE OR REPLACE FUNCTION ai.drop_vectorizer(name text, drop_all boolean DEFAULT false)
 RETURNS void
 LANGUAGE sql
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
   select ai.drop_vectorizer(v.id, drop_all)
   from ai.vectorizer v
   where v.name operator(pg_catalog.=) drop_vectorizer.name;
$function$

```
</details>

---

### Embedding Configuration (5 functions)

#### `embedding_litellm(model text, dimensions integer, api_key_name text DEFAULT NULL::text, extra_options jsonb DEFAULT NULL::jsonb)`

**Returns:** `jsonb`

**Language:** plpgsql
**Volatility:** immutable

<details>
<summary>View Definition</summary>

```sql
CREATE OR REPLACE FUNCTION ai.embedding_litellm(model text, dimensions integer, api_key_name text DEFAULT NULL::text, extra_options jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
begin
    return json_strip_nulls(json_build_object
    ( 'implementation', 'litellm'
    , 'config_type', 'embedding'
    , 'model', model
    , 'dimensions', dimensions
    , 'api_key_name', api_key_name
    , 'extra_options', extra_options
    ));
end
$function$

```
</details>

#### `embedding_ollama(model text, dimensions integer, base_url text DEFAULT NULL::text, options jsonb DEFAULT NULL::jsonb, keep_alive text DEFAULT NULL::text)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

<details>
<summary>View Definition</summary>

```sql
CREATE OR REPLACE FUNCTION ai.embedding_ollama(model text, dimensions integer, base_url text DEFAULT NULL::text, options jsonb DEFAULT NULL::jsonb, keep_alive text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
    select json_strip_nulls(json_build_object
    ( 'implementation', 'ollama'
    , 'config_type', 'embedding'
    , 'model', model
    , 'dimensions', dimensions
    , 'base_url', base_url
    , 'options', options
    , 'keep_alive', keep_alive
    ))
$function$

```
</details>

#### `embedding_openai(model text, dimensions integer, chat_user text DEFAULT NULL::text, api_key_name text DEFAULT 'OPENAI_API_KEY'::text, base_url text DEFAULT NULL::text)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

<details>
<summary>View Definition</summary>

```sql
CREATE OR REPLACE FUNCTION ai.embedding_openai(model text, dimensions integer, chat_user text DEFAULT NULL::text, api_key_name text DEFAULT 'OPENAI_API_KEY'::text, base_url text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
    select json_strip_nulls(json_build_object
    ( 'implementation', 'openai'
    , 'config_type', 'embedding'
    , 'model', model
    , 'dimensions', dimensions
    , 'user', chat_user
    , 'api_key_name', api_key_name
    , 'base_url', base_url
    ))
$function$

```
</details>

#### `embedding_sentence_transformers(model text DEFAULT 'nomic-ai/nomic-embed-text-v1.5'::text, dimensions integer DEFAULT 768)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

<details>
<summary>View Definition</summary>

```sql
CREATE OR REPLACE FUNCTION ai.embedding_sentence_transformers(model text DEFAULT 'nomic-ai/nomic-embed-text-v1.5'::text, dimensions integer DEFAULT 768)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
    select json_build_object
    ( 'implementation', 'sentence_transformers'
    , 'config_type', 'embedding'
    , 'model', model
    , 'dimensions', dimensions
    )
$function$

```
</details>

#### `embedding_voyageai(model text, dimensions integer, input_type text DEFAULT 'document'::text, api_key_name text DEFAULT 'VOYAGE_API_KEY'::text)`

**Returns:** `jsonb`

**Language:** plpgsql
**Volatility:** immutable

<details>
<summary>View Definition</summary>

```sql
CREATE OR REPLACE FUNCTION ai.embedding_voyageai(model text, dimensions integer, input_type text DEFAULT 'document'::text, api_key_name text DEFAULT 'VOYAGE_API_KEY'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
begin
    if input_type is not null and input_type not in ('query', 'document') then
        -- Note: purposefully not using an enum here because types make life complicated
        raise exception 'invalid input_type for voyage ai "%"', input_type;
    end if;

    return json_strip_nulls(json_build_object
    ( 'implementation', 'voyageai'
    , 'config_type', 'embedding'
    , 'model', model
    , 'dimensions', dimensions
    , 'input_type', input_type
    , 'api_key_name', api_key_name
    ));
end
$function$

```
</details>

---

### Loading Configuration (2 functions)

#### `loading_column(column_name name, retries integer DEFAULT 6)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `loading_uri(column_name name, retries integer DEFAULT 6, aws_role_arn text DEFAULT NULL::text)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

---

### Parsing Configuration (4 functions)

#### `parsing_auto()`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `parsing_docling()`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `parsing_none()`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `parsing_pymupdf()`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

---

### Chunking Configuration (3 functions)

#### `chunking_character_text_splitter(chunk_size integer DEFAULT 800, chunk_overlap integer DEFAULT 400, separator text DEFAULT '

'::text, is_separator_regex boolean DEFAULT false)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `chunking_none()`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `chunking_recursive_character_text_splitter(chunk_size integer DEFAULT 800, chunk_overlap integer DEFAULT 400, separators text[] DEFAULT ARRAY['

'::text, '
'::text, '.'::text, '?'::text, '!'::text, ' '::text, ''::text], is_separator_regex boolean DEFAULT false)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

---

### Destination Configuration (2 functions)

#### `destination_column(embedding_column name)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `destination_table(destination name DEFAULT NULL::name, target_schema name DEFAULT NULL::name, target_table name DEFAULT NULL::name, view_schema name DEFAULT NULL::name, view_name name DEFAULT NULL::name)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

---

### Indexing Configuration (4 functions)

#### `indexing_default()`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `indexing_diskann(min_rows integer DEFAULT 100000, storage_layout text DEFAULT NULL::text, num_neighbors integer DEFAULT NULL::integer, search_list_size integer DEFAULT NULL::integer, max_alpha double precision DEFAULT NULL::double precision, num_dimensions integer DEFAULT NULL::integer, num_bits_per_dimension integer DEFAULT NULL::integer, create_when_queue_empty boolean DEFAULT true)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `indexing_hnsw(min_rows integer DEFAULT 100000, opclass text DEFAULT 'vector_cosine_ops'::text, m integer DEFAULT NULL::integer, ef_construction integer DEFAULT NULL::integer, create_when_queue_empty boolean DEFAULT true)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `indexing_none()`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

---

### Scheduling Management (5 functions)

#### `_vectorizer_schedule_job(vectorizer_id integer, scheduling jsonb)`

**Returns:** `bigint`

**Language:** plpgsql
**Volatility:** volatile

#### `disable_vectorizer_schedule(vectorizer_id integer)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `disable_vectorizer_schedule(name text)`

**Returns:** `void`

**Language:** sql
**Volatility:** volatile

#### `enable_vectorizer_schedule(vectorizer_id integer)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `enable_vectorizer_schedule(name text)`

**Returns:** `void`

**Language:** sql
**Volatility:** volatile

---

### Internal Functions (164 functions)

#### `_evaluate_destination(destination jsonb, source_schema name, source_table name)`

**Returns:** `jsonb`

**Language:** plpgsql
**Volatility:** stable

#### `_resolve_indexing_default()`

**Returns:** `jsonb`

**Language:** plpgsql
**Volatility:** volatile

#### `_resolve_scheduling_default()`

**Returns:** `jsonb`

**Language:** plpgsql
**Volatility:** volatile

#### `_sc_obj(catalog_id integer)`

**Returns:** `TABLE(id bigint, classid oid, objid oid, objsubid integer, objtype text, objnames text[], objargs text[], description text)`

**Language:** plpgsql
**Volatility:** stable

#### `_semantic_catalog_make_triggers(semantic_catalog_id integer)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_validate_chunking(config jsonb)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** stable

#### `_validate_destination(destination jsonb, chunking jsonb)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** immutable

#### `_validate_destination_can_create_objects(destination jsonb)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** stable

#### `_validate_embedding(config jsonb)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** immutable

#### `_validate_formatting(config jsonb, source_schema name, source_table name)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** immutable

#### `_validate_formatting_python_template(config jsonb, source_schema name, source_table name)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** stable

#### `_validate_indexing(config jsonb)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** immutable

#### `_validate_indexing_diskann(config jsonb)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** immutable

#### `_validate_indexing_hnsw(config jsonb)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** immutable

#### `_validate_loading(config jsonb, source_schema name, source_table name)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** stable

#### `_validate_parsing(parsing jsonb, loading jsonb, source_schema name, source_table name)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** stable

#### `_validate_processing(config jsonb)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** immutable

#### `_validate_scheduling(config jsonb)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** immutable

#### `_vectorizer_add_embedding_column(source_schema name, source_table name, dimensions integer, embedding_column name)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_build_trigger_definition(queue_schema name, queue_table name, target_schema name, target_table name, source_schema name, source_table name, source_pk jsonb)`

**Returns:** `text`

**Language:** plpgsql
**Volatility:** immutable

#### `_vectorizer_create_destination_column(source_schema name, source_table name, dimensions integer, destination jsonb)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_create_destination_table(source_schema name, source_table name, source_pk jsonb, dimensions integer, destination jsonb, grant_to name[])`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_create_queue_failed_table(queue_schema name, queue_failed_table name, source_pk jsonb, grant_to name[])`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_create_queue_table(queue_schema name, queue_table name, source_pk jsonb, grant_to name[])`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_create_source_trigger(trigger_name name, queue_schema name, queue_table name, source_schema name, source_table name, target_schema name, target_table name, source_pk jsonb)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_create_target_table(source_pk jsonb, target_schema name, target_table name, dimensions integer, grant_to name[])`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_create_vector_index(target_schema name, target_table name, indexing jsonb, column_name name DEFAULT 'embedding'::name)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_create_view(view_schema name, view_name name, source_schema name, source_table name, source_pk jsonb, target_schema name, target_table name, grant_to name[])`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_grant_to_source(source_schema name, source_table name, grant_to name[])`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_grant_to_vectorizer(grant_to name[])`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_job(IN job_id integer DEFAULT NULL::integer, IN config jsonb DEFAULT NULL::jsonb)`

**Returns:** `None`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_should_create_vector_index(vectorizer ai.vectorizer)`

**Returns:** `boolean`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_source_pk(source_table regclass)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** stable

#### `_vectorizer_src_trg_1()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_132()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_133()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_134()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_135()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_136()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_137()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_2()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_48()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_49()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_50()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_51()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_52()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_53()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_54()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_55()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_56()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_58()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_59()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_60()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_61()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_62()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_63()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_71()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_72()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_73()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_74()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_75()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_76()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_77()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_78()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_79()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_80()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_81()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_82()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_83()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_84()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_85()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_src_trg_86()`

**Returns:** `trigger`

**Language:** plpgsql
**Volatility:** volatile

#### `_vectorizer_vector_index_exists(target_schema name, target_table name, indexing jsonb, column_name name DEFAULT 'embedding'::name)`

**Returns:** `boolean`

**Language:** plpgsql
**Volatility:** volatile

#### `_worker_heartbeat(worker_id uuid, num_successes_since_last_heartbeat integer, num_errors_since_last_heartbeat integer, error_message text)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_worker_progress(worker_id uuid, worker_vectorizer_id integer, num_successes integer, error_message text)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `_worker_start(version text, expected_heartbeat_interval interval)`

**Returns:** `uuid`

**Language:** plpgsql
**Volatility:** volatile

#### `anthropic_generate(model text, messages jsonb, max_tokens integer DEFAULT 1024, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, base_url text DEFAULT NULL::text, timeout double precision DEFAULT NULL::double precision, max_retries integer DEFAULT NULL::integer, system_prompt text DEFAULT NULL::text, user_id text DEFAULT NULL::text, stop_sequences text[] DEFAULT NULL::text[], temperature double precision DEFAULT NULL::double precision, tool_choice jsonb DEFAULT NULL::jsonb, tools jsonb DEFAULT NULL::jsonb, top_k integer DEFAULT NULL::integer, top_p double precision DEFAULT NULL::double precision, "verbose" boolean DEFAULT false)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** volatile

#### `anthropic_list_models(api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, base_url text DEFAULT NULL::text, "verbose" boolean DEFAULT false)`

**Returns:** `TABLE(id text, name text, created timestamp with time zone)`

**Language:** plpython3u
**Volatility:** volatile

#### `chunk_text(input text, chunk_size integer DEFAULT NULL::integer, chunk_overlap integer DEFAULT NULL::integer, separator text DEFAULT NULL::text, is_separator_regex boolean DEFAULT false)`

**Returns:** `TABLE(seq bigint, chunk text)`

**Language:** plpython3u
**Volatility:** volatile

#### `chunk_text_recursively(input text, chunk_size integer DEFAULT NULL::integer, chunk_overlap integer DEFAULT NULL::integer, separators text[] DEFAULT NULL::text[], is_separator_regex boolean DEFAULT false)`

**Returns:** `TABLE(seq bigint, chunk text)`

**Language:** plpython3u
**Volatility:** volatile

#### `cohere_chat_complete(model text, messages jsonb, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, tools jsonb DEFAULT NULL::jsonb, documents jsonb DEFAULT NULL::jsonb, citation_options jsonb DEFAULT NULL::jsonb, response_format jsonb DEFAULT NULL::jsonb, safety_mode text DEFAULT NULL::text, max_tokens integer DEFAULT NULL::integer, stop_sequences text[] DEFAULT NULL::text[], temperature double precision DEFAULT NULL::double precision, seed integer DEFAULT NULL::integer, frequency_penalty double precision DEFAULT NULL::double precision, presence_penalty double precision DEFAULT NULL::double precision, k integer DEFAULT NULL::integer, p double precision DEFAULT NULL::double precision, logprobs boolean DEFAULT NULL::boolean, tool_choice text DEFAULT NULL::text, strict_tools boolean DEFAULT NULL::boolean, "verbose" boolean DEFAULT false)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** volatile

#### `cohere_classify(model text, inputs text[], api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, examples jsonb DEFAULT NULL::jsonb, truncate_long_inputs text DEFAULT NULL::text, "verbose" boolean DEFAULT false)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** immutable

#### `cohere_classify_simple(model text, inputs text[], api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, examples jsonb DEFAULT NULL::jsonb, truncate_long_inputs text DEFAULT NULL::text, "verbose" boolean DEFAULT false)`

**Returns:** `TABLE(input text, prediction text, confidence double precision)`

**Language:** plpython3u
**Volatility:** immutable

#### `cohere_detokenize(model text, tokens integer[], api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, "verbose" boolean DEFAULT false)`

**Returns:** `text`

**Language:** plpython3u
**Volatility:** immutable

#### `cohere_embed(model text, input_text text, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, input_type text DEFAULT NULL::text, truncate_long_inputs text DEFAULT NULL::text, "verbose" boolean DEFAULT false)`

**Returns:** `vector`

**Language:** plpython3u
**Volatility:** immutable

#### `cohere_list_models(api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, endpoint text DEFAULT NULL::text, default_only boolean DEFAULT NULL::boolean, "verbose" boolean DEFAULT false)`

**Returns:** `TABLE(name text, endpoints text[], finetuned boolean, context_length integer, tokenizer_url text, default_endpoints text[])`

**Language:** plpython3u
**Volatility:** volatile

#### `cohere_rerank(model text, query text, documents text[], api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, top_n integer DEFAULT NULL::integer, max_tokens_per_doc integer DEFAULT NULL::integer, "verbose" boolean DEFAULT false)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** immutable

#### `cohere_rerank_simple(model text, query text, documents text[], api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, top_n integer DEFAULT NULL::integer, max_tokens_per_doc integer DEFAULT NULL::integer, "verbose" boolean DEFAULT false)`

**Returns:** `TABLE(index integer, document text, relevance_score double precision)`

**Language:** sql
**Volatility:** immutable

#### `cohere_tokenize(model text, text_input text, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, "verbose" boolean DEFAULT false)`

**Returns:** `integer[]`

**Language:** plpython3u
**Volatility:** immutable

#### `create_semantic_catalog(catalog_name name DEFAULT 'default'::name, embedding_name name DEFAULT NULL::name, embedding_config jsonb DEFAULT ai.embedding_sentence_transformers())`

**Returns:** `integer`

**Language:** plpgsql
**Volatility:** volatile

#### `drop_semantic_catalog(catalog_name name)`

**Returns:** `integer`

**Language:** plpgsql
**Volatility:** volatile

#### `execute_vectorizer(vectorizer_name text)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `execute_vectorizer(vectorizer_id integer)`

**Returns:** `void`

**Language:** plpython3u
**Volatility:** volatile

#### `formatting_python_template(template text DEFAULT '$chunk'::text)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `grant_ai_usage(to_user name, admin boolean DEFAULT false)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `grant_secret(secret_name text, grant_to_role text)`

**Returns:** `void`

**Language:** sql
**Volatility:** volatile

#### `grant_to(VARIADIC grantees name[])`

**Returns:** `name[]`

**Language:** sql
**Volatility:** volatile

#### `grant_to()`

**Returns:** `name[]`

**Language:** sql
**Volatility:** volatile

#### `grant_vectorizer_usage(to_user name, admin boolean DEFAULT false)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `litellm_embed(model text, input_text text, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, extra_options jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false)`

**Returns:** `vector`

**Language:** plpython3u
**Volatility:** immutable

#### `litellm_embed(model text, input_texts text[], api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, extra_options jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false)`

**Returns:** `TABLE(index integer, embedding vector)`

**Language:** plpython3u
**Volatility:** immutable

#### `load_dataset(name text, config_name text DEFAULT NULL::text, split text DEFAULT NULL::text, schema_name name DEFAULT 'public'::name, table_name name DEFAULT NULL::name, if_table_exists text DEFAULT 'error'::text, field_types jsonb DEFAULT NULL::jsonb, batch_size integer DEFAULT 5000, max_batches integer DEFAULT NULL::integer, kwargs jsonb DEFAULT '{}'::jsonb)`

**Returns:** `bigint`

**Language:** plpython3u
**Volatility:** volatile

#### `load_dataset_multi_txn(IN name text, IN config_name text DEFAULT NULL::text, IN split text DEFAULT NULL::text, IN schema_name name DEFAULT 'public'::name, IN table_name name DEFAULT NULL::name, IN if_table_exists text DEFAULT 'error'::text, IN field_types jsonb DEFAULT NULL::jsonb, IN batch_size integer DEFAULT 5000, IN max_batches integer DEFAULT NULL::integer, IN commit_every_n_batches integer DEFAULT 1, IN kwargs jsonb DEFAULT '{}'::jsonb)`

**Returns:** `None`

**Language:** plpython3u
**Volatility:** volatile

#### `ollama_chat_complete(model text, messages jsonb, host text DEFAULT NULL::text, keep_alive text DEFAULT NULL::text, chat_options jsonb DEFAULT NULL::jsonb, tools jsonb DEFAULT NULL::jsonb, response_format jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** volatile

#### `ollama_embed(model text, input_text text, host text DEFAULT NULL::text, keep_alive text DEFAULT NULL::text, embedding_options jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false)`

**Returns:** `vector`

**Language:** plpython3u
**Volatility:** immutable

#### `ollama_generate(model text, prompt text, host text DEFAULT NULL::text, images bytea[] DEFAULT NULL::bytea[], keep_alive text DEFAULT NULL::text, embedding_options jsonb DEFAULT NULL::jsonb, system_prompt text DEFAULT NULL::text, template text DEFAULT NULL::text, context integer[] DEFAULT NULL::integer[], "verbose" boolean DEFAULT false)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** volatile

#### `ollama_list_models(host text DEFAULT NULL::text, "verbose" boolean DEFAULT false)`

**Returns:** `TABLE(name text, model text, size bigint, digest text, family text, format text, families jsonb, parent_model text, parameter_size text, quantization_level text, modified_at timestamp with time zone)`

**Language:** plpython3u
**Volatility:** volatile

#### `ollama_ps(host text DEFAULT NULL::text, "verbose" boolean DEFAULT false)`

**Returns:** `TABLE(name text, model text, size bigint, digest text, parent_model text, format text, family text, families jsonb, parameter_size text, quantization_level text, expires_at timestamp with time zone, size_vram bigint)`

**Language:** plpython3u
**Volatility:** volatile

#### `openai_chat_complete(model text, messages jsonb, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, frequency_penalty double precision DEFAULT NULL::double precision, logit_bias jsonb DEFAULT NULL::jsonb, logprobs boolean DEFAULT NULL::boolean, top_logprobs integer DEFAULT NULL::integer, max_tokens integer DEFAULT NULL::integer, max_completion_tokens integer DEFAULT NULL::integer, n integer DEFAULT NULL::integer, presence_penalty double precision DEFAULT NULL::double precision, response_format jsonb DEFAULT NULL::jsonb, seed integer DEFAULT NULL::integer, stop text DEFAULT NULL::text, temperature double precision DEFAULT NULL::double precision, top_p double precision DEFAULT NULL::double precision, tools jsonb DEFAULT NULL::jsonb, tool_choice text DEFAULT NULL::text, openai_user text DEFAULT NULL::text, extra_headers jsonb DEFAULT NULL::jsonb, extra_query jsonb DEFAULT NULL::jsonb, extra_body jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false, client_config jsonb DEFAULT NULL::jsonb)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** volatile

#### `openai_chat_complete_simple(message text, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, "verbose" boolean DEFAULT false, client_config jsonb DEFAULT NULL::jsonb)`

**Returns:** `text`

**Language:** plpgsql
**Volatility:** volatile

#### `openai_chat_complete_with_raw_response(model text, messages jsonb, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, frequency_penalty double precision DEFAULT NULL::double precision, logit_bias jsonb DEFAULT NULL::jsonb, logprobs boolean DEFAULT NULL::boolean, top_logprobs integer DEFAULT NULL::integer, max_tokens integer DEFAULT NULL::integer, max_completion_tokens integer DEFAULT NULL::integer, n integer DEFAULT NULL::integer, presence_penalty double precision DEFAULT NULL::double precision, response_format jsonb DEFAULT NULL::jsonb, seed integer DEFAULT NULL::integer, stop text DEFAULT NULL::text, temperature double precision DEFAULT NULL::double precision, top_p double precision DEFAULT NULL::double precision, tools jsonb DEFAULT NULL::jsonb, tool_choice text DEFAULT NULL::text, openai_user text DEFAULT NULL::text, extra_headers jsonb DEFAULT NULL::jsonb, extra_query jsonb DEFAULT NULL::jsonb, extra_body jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false, client_config jsonb DEFAULT NULL::jsonb)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** volatile

#### `openai_client_config(base_url text DEFAULT NULL::text, timeout_seconds double precision DEFAULT NULL::double precision, organization text DEFAULT NULL::text, project text DEFAULT NULL::text, max_retries integer DEFAULT NULL::integer, default_headers jsonb DEFAULT NULL::jsonb, default_query jsonb DEFAULT NULL::jsonb)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** immutable

#### `openai_detokenize(model text, tokens integer[])`

**Returns:** `text`

**Language:** plpython3u
**Volatility:** immutable

#### `openai_embed(model text, input_text text, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, dimensions integer DEFAULT NULL::integer, openai_user text DEFAULT NULL::text, extra_headers jsonb DEFAULT NULL::jsonb, extra_query jsonb DEFAULT NULL::jsonb, extra_body jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false, client_config jsonb DEFAULT NULL::jsonb)`

**Returns:** `vector`

**Language:** plpython3u
**Volatility:** immutable

#### `openai_embed(model text, input_texts text[], api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, dimensions integer DEFAULT NULL::integer, openai_user text DEFAULT NULL::text, extra_headers jsonb DEFAULT NULL::jsonb, extra_query jsonb DEFAULT NULL::jsonb, extra_body jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false, client_config jsonb DEFAULT NULL::jsonb)`

**Returns:** `TABLE(index integer, embedding vector)`

**Language:** plpython3u
**Volatility:** immutable

#### `openai_embed(model text, input_tokens integer[], api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, dimensions integer DEFAULT NULL::integer, openai_user text DEFAULT NULL::text, extra_headers jsonb DEFAULT NULL::jsonb, extra_query jsonb DEFAULT NULL::jsonb, extra_body jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false, client_config jsonb DEFAULT NULL::jsonb)`

**Returns:** `vector`

**Language:** plpython3u
**Volatility:** immutable

#### `openai_embed_with_raw_response(model text, input_text text, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, dimensions integer DEFAULT NULL::integer, openai_user text DEFAULT NULL::text, extra_headers jsonb DEFAULT NULL::jsonb, extra_query jsonb DEFAULT NULL::jsonb, extra_body jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false, client_config jsonb DEFAULT NULL::jsonb)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** immutable

#### `openai_embed_with_raw_response(model text, input_texts text[], api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, dimensions integer DEFAULT NULL::integer, openai_user text DEFAULT NULL::text, extra_headers jsonb DEFAULT NULL::jsonb, extra_query jsonb DEFAULT NULL::jsonb, extra_body jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false, client_config jsonb DEFAULT NULL::jsonb)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** immutable

#### `openai_embed_with_raw_response(model text, input_tokens integer[], api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, dimensions integer DEFAULT NULL::integer, openai_user text DEFAULT NULL::text, extra_headers jsonb DEFAULT NULL::jsonb, extra_query jsonb DEFAULT NULL::jsonb, extra_body jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false, client_config jsonb DEFAULT NULL::jsonb)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** immutable

#### `openai_list_models(api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, extra_headers jsonb DEFAULT NULL::jsonb, extra_query jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false, client_config jsonb DEFAULT NULL::jsonb)`

**Returns:** `TABLE(id text, created timestamp with time zone, owned_by text)`

**Language:** plpython3u
**Volatility:** volatile

#### `openai_list_models_with_raw_response(api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, extra_headers jsonb DEFAULT NULL::jsonb, extra_query jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false, client_config jsonb DEFAULT NULL::jsonb)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** volatile

#### `openai_moderate(model text, input_text text, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, extra_headers jsonb DEFAULT NULL::jsonb, extra_query jsonb DEFAULT NULL::jsonb, extra_body jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false, client_config jsonb DEFAULT NULL::jsonb)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** immutable

#### `openai_moderate_with_raw_response(model text, input_text text, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, extra_headers jsonb DEFAULT NULL::jsonb, extra_query jsonb DEFAULT NULL::jsonb, extra_body jsonb DEFAULT NULL::jsonb, "verbose" boolean DEFAULT false, client_config jsonb DEFAULT NULL::jsonb)`

**Returns:** `jsonb`

**Language:** plpython3u
**Volatility:** immutable

#### `openai_tokenize(model text, text_input text)`

**Returns:** `integer[]`

**Language:** plpython3u
**Volatility:** immutable

#### `processing_default(batch_size integer DEFAULT NULL::integer, concurrency integer DEFAULT NULL::integer)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `reveal_secret(secret_name text, use_cache boolean DEFAULT true)`

**Returns:** `text`

**Language:** plpython3u
**Volatility:** stable

#### `revoke_secret(secret_name text, revoke_from_role text)`

**Returns:** `void`

**Language:** sql
**Volatility:** volatile

#### `sc_add_embedding(config jsonb, embedding_name name DEFAULT NULL::name, catalog_name name DEFAULT 'default'::name)`

**Returns:** `ai.semantic_catalog_embedding`

**Language:** plpgsql
**Volatility:** volatile

#### `sc_add_fact(description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** plpgsql
**Volatility:** volatile

#### `sc_add_sql_desc(sql text, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** plpgsql
**Volatility:** volatile

#### `sc_drop_embedding(embedding_name name, catalog_name name DEFAULT 'default'::name)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `sc_grant_admin(role_name name)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `sc_grant_obj_read(catalog_name name, role_name name)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `sc_grant_read(catalog_name name, role_name name)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `sc_grant_write(catalog_name name, role_name name)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `sc_set_agg_desc(classid oid, objid oid, schema_name name, agg_name name, objargs text[], description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_set_agg_desc(a regprocedure, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_set_func_desc(classid oid, objid oid, schema_name name, func_name name, objargs text[], description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_set_func_desc(f regprocedure, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_set_obj_desc(classid oid, objid oid, objsubid integer, objtype text, objnames text[], objargs text[], description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** plpgsql
**Volatility:** volatile

#### `sc_set_obj_desc(objtype text, objnames text[], objargs text[], description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** plpgsql
**Volatility:** volatile

#### `sc_set_proc_desc(classid oid, objid oid, schema_name name, proc_name name, objargs text[], description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_set_proc_desc(p regprocedure, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_set_table_col_desc(classid oid, objid oid, objsubid integer, schema_name name, table_name name, column_name name, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_set_table_col_desc(t regclass, column_name name, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_set_table_desc(classid oid, objid oid, schema_name name, table_name name, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_set_table_desc(t regclass, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_set_view_col_desc(classid oid, objid oid, objsubid integer, schema_name name, view_name name, column_name name, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_set_view_col_desc(v regclass, column_name name, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_set_view_desc(classid oid, objid oid, schema_name name, view_name name, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_set_view_desc(v regclass, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** volatile

#### `sc_update_fact(id bigint, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `sc_update_sql_desc(id bigint, sql text, description text, catalog_name name DEFAULT 'default'::name)`

**Returns:** `void`

**Language:** plpgsql
**Volatility:** volatile

#### `scheduling_default()`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `scheduling_none()`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `scheduling_timescaledb(schedule_interval interval DEFAULT '00:05:00'::interval, initial_start timestamp with time zone DEFAULT NULL::timestamp with time zone, fixed_schedule boolean DEFAULT NULL::boolean, timezone text DEFAULT NULL::text)`

**Returns:** `jsonb`

**Language:** sql
**Volatility:** immutable

#### `set_scheduling(vectorizer_id integer, scheduling jsonb DEFAULT ai.scheduling_default(), indexing jsonb DEFAULT ai.indexing_default())`

**Returns:** `jsonb`

**Language:** plpgsql
**Volatility:** volatile

#### `vectorizer_embed(embedding_config jsonb, input_text text, input_type text DEFAULT NULL::text)`

**Returns:** `vector`

**Language:** plpgsql
**Volatility:** immutable

#### `vectorizer_embed(vectorizer_id integer, input_text text, input_type text DEFAULT NULL::text)`

**Returns:** `vector`

**Language:** sql
**Volatility:** stable

#### `vectorizer_embed(name text, input_text text, input_type text DEFAULT NULL::text)`

**Returns:** `vector`

**Language:** sql
**Volatility:** stable

#### `vectorizer_queue_pending(vectorizer_id integer, exact_count boolean DEFAULT false)`

**Returns:** `bigint`

**Language:** plpgsql
**Volatility:** stable

#### `vectorizer_queue_pending(name text, exact_count boolean DEFAULT false)`

**Returns:** `bigint`

**Language:** sql
**Volatility:** stable

#### `voyageai_embed(model text, input_text text, input_type text DEFAULT NULL::text, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, "verbose" boolean DEFAULT false)`

**Returns:** `vector`

**Language:** plpython3u
**Volatility:** immutable

#### `voyageai_embed(model text, input_texts text[], input_type text DEFAULT NULL::text, api_key text DEFAULT NULL::text, api_key_name text DEFAULT NULL::text, "verbose" boolean DEFAULT false)`

**Returns:** `TABLE(index integer, embedding vector)`

**Language:** plpython3u
**Volatility:** immutable

---

## Custom Types

### `ai.__secret_permissions` (base)

**Formatted Type:** `ai._secret_permissions[]`

### `ai.__vectorizer_errors` (base)

**Formatted Type:** `ai._vectorizer_errors[]`

### `ai.__vectorizer_q_1` (base)

**Formatted Type:** `ai._vectorizer_q_1[]`

### `ai.__vectorizer_q_132` (base)

**Formatted Type:** `ai._vectorizer_q_132[]`

### `ai.__vectorizer_q_133` (base)

**Formatted Type:** `ai._vectorizer_q_133[]`

### `ai.__vectorizer_q_134` (base)

**Formatted Type:** `ai._vectorizer_q_134[]`

### `ai.__vectorizer_q_135` (base)

**Formatted Type:** `ai._vectorizer_q_135[]`

### `ai.__vectorizer_q_136` (base)

**Formatted Type:** `ai._vectorizer_q_136[]`

### `ai.__vectorizer_q_137` (base)

**Formatted Type:** `ai._vectorizer_q_137[]`

### `ai.__vectorizer_q_2` (base)

**Formatted Type:** `ai._vectorizer_q_2[]`

### `ai.__vectorizer_q_48` (base)

**Formatted Type:** `ai._vectorizer_q_48[]`

### `ai.__vectorizer_q_49` (base)

**Formatted Type:** `ai._vectorizer_q_49[]`

### `ai.__vectorizer_q_50` (base)

**Formatted Type:** `ai._vectorizer_q_50[]`

### `ai.__vectorizer_q_51` (base)

**Formatted Type:** `ai._vectorizer_q_51[]`

### `ai.__vectorizer_q_52` (base)

**Formatted Type:** `ai._vectorizer_q_52[]`

### `ai.__vectorizer_q_53` (base)

**Formatted Type:** `ai._vectorizer_q_53[]`

### `ai.__vectorizer_q_54` (base)

**Formatted Type:** `ai._vectorizer_q_54[]`

### `ai.__vectorizer_q_55` (base)

**Formatted Type:** `ai._vectorizer_q_55[]`

### `ai.__vectorizer_q_56` (base)

**Formatted Type:** `ai._vectorizer_q_56[]`

### `ai.__vectorizer_q_58` (base)

**Formatted Type:** `ai._vectorizer_q_58[]`

### `ai.__vectorizer_q_59` (base)

**Formatted Type:** `ai._vectorizer_q_59[]`

### `ai.__vectorizer_q_60` (base)

**Formatted Type:** `ai._vectorizer_q_60[]`

### `ai.__vectorizer_q_61` (base)

**Formatted Type:** `ai._vectorizer_q_61[]`

### `ai.__vectorizer_q_62` (base)

**Formatted Type:** `ai._vectorizer_q_62[]`

### `ai.__vectorizer_q_63` (base)

**Formatted Type:** `ai._vectorizer_q_63[]`

### `ai.__vectorizer_q_71` (base)

**Formatted Type:** `ai._vectorizer_q_71[]`

### `ai.__vectorizer_q_72` (base)

**Formatted Type:** `ai._vectorizer_q_72[]`

### `ai.__vectorizer_q_73` (base)

**Formatted Type:** `ai._vectorizer_q_73[]`

### `ai.__vectorizer_q_74` (base)

**Formatted Type:** `ai._vectorizer_q_74[]`

### `ai.__vectorizer_q_75` (base)

**Formatted Type:** `ai._vectorizer_q_75[]`

### `ai.__vectorizer_q_76` (base)

**Formatted Type:** `ai._vectorizer_q_76[]`

### `ai.__vectorizer_q_77` (base)

**Formatted Type:** `ai._vectorizer_q_77[]`

### `ai.__vectorizer_q_78` (base)

**Formatted Type:** `ai._vectorizer_q_78[]`

### `ai.__vectorizer_q_79` (base)

**Formatted Type:** `ai._vectorizer_q_79[]`

### `ai.__vectorizer_q_80` (base)

**Formatted Type:** `ai._vectorizer_q_80[]`

### `ai.__vectorizer_q_81` (base)

**Formatted Type:** `ai._vectorizer_q_81[]`

### `ai.__vectorizer_q_82` (base)

**Formatted Type:** `ai._vectorizer_q_82[]`

### `ai.__vectorizer_q_83` (base)

**Formatted Type:** `ai._vectorizer_q_83[]`

### `ai.__vectorizer_q_84` (base)

**Formatted Type:** `ai._vectorizer_q_84[]`

### `ai.__vectorizer_q_85` (base)

**Formatted Type:** `ai._vectorizer_q_85[]`

### `ai.__vectorizer_q_86` (base)

**Formatted Type:** `ai._vectorizer_q_86[]`

### `ai.__vectorizer_q_failed_1` (base)

**Formatted Type:** `ai._vectorizer_q_failed_1[]`

### `ai.__vectorizer_q_failed_132` (base)

**Formatted Type:** `ai._vectorizer_q_failed_132[]`

### `ai.__vectorizer_q_failed_133` (base)

**Formatted Type:** `ai._vectorizer_q_failed_133[]`

### `ai.__vectorizer_q_failed_134` (base)

**Formatted Type:** `ai._vectorizer_q_failed_134[]`

### `ai.__vectorizer_q_failed_135` (base)

**Formatted Type:** `ai._vectorizer_q_failed_135[]`

### `ai.__vectorizer_q_failed_136` (base)

**Formatted Type:** `ai._vectorizer_q_failed_136[]`

### `ai.__vectorizer_q_failed_137` (base)

**Formatted Type:** `ai._vectorizer_q_failed_137[]`

### `ai.__vectorizer_q_failed_2` (base)

**Formatted Type:** `ai._vectorizer_q_failed_2[]`

### `ai.__vectorizer_q_failed_48` (base)

**Formatted Type:** `ai._vectorizer_q_failed_48[]`

### `ai.__vectorizer_q_failed_49` (base)

**Formatted Type:** `ai._vectorizer_q_failed_49[]`

### `ai.__vectorizer_q_failed_50` (base)

**Formatted Type:** `ai._vectorizer_q_failed_50[]`

### `ai.__vectorizer_q_failed_51` (base)

**Formatted Type:** `ai._vectorizer_q_failed_51[]`

### `ai.__vectorizer_q_failed_52` (base)

**Formatted Type:** `ai._vectorizer_q_failed_52[]`

### `ai.__vectorizer_q_failed_53` (base)

**Formatted Type:** `ai._vectorizer_q_failed_53[]`

### `ai.__vectorizer_q_failed_54` (base)

**Formatted Type:** `ai._vectorizer_q_failed_54[]`

### `ai.__vectorizer_q_failed_55` (base)

**Formatted Type:** `ai._vectorizer_q_failed_55[]`

### `ai.__vectorizer_q_failed_56` (base)

**Formatted Type:** `ai._vectorizer_q_failed_56[]`

### `ai.__vectorizer_q_failed_58` (base)

**Formatted Type:** `ai._vectorizer_q_failed_58[]`

### `ai.__vectorizer_q_failed_59` (base)

**Formatted Type:** `ai._vectorizer_q_failed_59[]`

### `ai.__vectorizer_q_failed_60` (base)

**Formatted Type:** `ai._vectorizer_q_failed_60[]`

### `ai.__vectorizer_q_failed_61` (base)

**Formatted Type:** `ai._vectorizer_q_failed_61[]`

### `ai.__vectorizer_q_failed_62` (base)

**Formatted Type:** `ai._vectorizer_q_failed_62[]`

### `ai.__vectorizer_q_failed_63` (base)

**Formatted Type:** `ai._vectorizer_q_failed_63[]`

### `ai.__vectorizer_q_failed_71` (base)

**Formatted Type:** `ai._vectorizer_q_failed_71[]`

### `ai.__vectorizer_q_failed_72` (base)

**Formatted Type:** `ai._vectorizer_q_failed_72[]`

### `ai.__vectorizer_q_failed_73` (base)

**Formatted Type:** `ai._vectorizer_q_failed_73[]`

### `ai.__vectorizer_q_failed_74` (base)

**Formatted Type:** `ai._vectorizer_q_failed_74[]`

### `ai.__vectorizer_q_failed_75` (base)

**Formatted Type:** `ai._vectorizer_q_failed_75[]`

### `ai.__vectorizer_q_failed_76` (base)

**Formatted Type:** `ai._vectorizer_q_failed_76[]`

### `ai.__vectorizer_q_failed_77` (base)

**Formatted Type:** `ai._vectorizer_q_failed_77[]`

### `ai.__vectorizer_q_failed_78` (base)

**Formatted Type:** `ai._vectorizer_q_failed_78[]`

### `ai.__vectorizer_q_failed_79` (base)

**Formatted Type:** `ai._vectorizer_q_failed_79[]`

### `ai.__vectorizer_q_failed_80` (base)

**Formatted Type:** `ai._vectorizer_q_failed_80[]`

### `ai.__vectorizer_q_failed_81` (base)

**Formatted Type:** `ai._vectorizer_q_failed_81[]`

### `ai.__vectorizer_q_failed_82` (base)

**Formatted Type:** `ai._vectorizer_q_failed_82[]`

### `ai.__vectorizer_q_failed_83` (base)

**Formatted Type:** `ai._vectorizer_q_failed_83[]`

### `ai.__vectorizer_q_failed_84` (base)

**Formatted Type:** `ai._vectorizer_q_failed_84[]`

### `ai.__vectorizer_q_failed_85` (base)

**Formatted Type:** `ai._vectorizer_q_failed_85[]`

### `ai.__vectorizer_q_failed_86` (base)

**Formatted Type:** `ai._vectorizer_q_failed_86[]`

### `ai._feature_flag` (base)

**Formatted Type:** `ai.feature_flag[]`

### `ai._migration` (base)

**Formatted Type:** `ai.migration[]`

### `ai._pgai_lib_feature_flag` (base)

**Formatted Type:** `ai.pgai_lib_feature_flag[]`

### `ai._pgai_lib_migration` (base)

**Formatted Type:** `ai.pgai_lib_migration[]`

### `ai._pgai_lib_version` (base)

**Formatted Type:** `ai.pgai_lib_version[]`

### `ai._secret_permissions_1` (base)

**Formatted Type:** `ai.secret_permissions[]`

### `ai._semantic_catalog` (base)

**Formatted Type:** `ai.semantic_catalog[]`

### `ai._semantic_catalog_embedding` (base)

**Formatted Type:** `ai.semantic_catalog_embedding[]`

### `ai._vectorizer` (base)

**Formatted Type:** `ai.vectorizer[]`

### `ai._vectorizer_errors_1` (base)

**Formatted Type:** `ai.vectorizer_errors[]`

### `ai._vectorizer_status` (base)

**Formatted Type:** `ai.vectorizer_status[]`

### `ai._vectorizer_worker_process` (base)

**Formatted Type:** `ai.vectorizer_worker_process[]`

### `ai._vectorizer_worker_progress` (base)

**Formatted Type:** `ai.vectorizer_worker_progress[]`

---

## Sequences

### `ai.semantic_catalog_embedding_id_seq`

### `ai.semantic_catalog_id_seq`

### `ai.vectorizer_id_seq`

---

## Usage Examples

### Creating a Vectorizer

```sql
-- Create a vectorizer for a table using Ollama embeddings
SELECT ai.create_vectorizer(
    'public.my_documents'::regclass,
    name => 'doc_embeddings',
    destination => ai.destination_table('doc_embeddings_store'),
    embedding => ai.embedding_ollama('nomic-embed-text', 768),
    chunking => ai.chunking_recursive_character_text_splitter(512, 50)
);
```

### Checking Vectorizer Status

```sql
-- View all vectorizers and their status
SELECT * FROM ai.vectorizer_status;
```

### Vector Search

```sql
-- Perform similarity search using embeddings
SELECT *
FROM doc_embeddings
ORDER BY embedding <=> ai.ollama_embed('nomic-embed-text', 'search query')
LIMIT 10;
```

### Managing Vectorizers

```sql
-- Disable vectorizer schedule
SELECT ai.disable_vectorizer_schedule(1);

-- Enable vectorizer schedule
SELECT ai.enable_vectorizer_schedule(1);

-- Drop a vectorizer
SELECT ai.drop_vectorizer(1);
```
