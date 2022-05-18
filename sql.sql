--CREATE USER mgmt WITH PASSWORD 'rootroot';

DO
$do$
BEGIN
   IF EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'mgmt') THEN

      RAISE NOTICE 'Role "mgmt" already exists. Skipping.';
   ELSE
      BEGIN   -- nested block
         CREATE ROLE mgmt LOGIN PASSWORD 'rootroot';
      EXCEPTION
         WHEN duplicate_object THEN
            RAISE NOTICE 'Role "mgmt" was just created by a concurrent transaction. Skipping.';
      END;
   END IF;
END
$do$;

create database mgmtdb;

GRANT ALL PRIVILEGES ON DATABASE mgmtdb TO mgmt;
GRANT ALL PRIVILEGES ON all tables in schema public TO mgmt;


 \c mgmtdb mgmt;
--
-- PostgreSQL database dump
--

-- Dumped from database version 10.19 (Ubuntu 10.19-0ubuntu0.18.04.1)
-- Dumped by pg_dump version 10.19 (Ubuntu 10.19-0ubuntu0.18.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ovpnclients; Type: TABLE; Schema: public; Owner: mgmt
--

CREATE TABLE public.ovpnclients (
    cn character varying(41) NOT NULL,
    ip character varying(15) NOT NULL,
    changedate timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    storename character varying(100) DEFAULT 0 NOT NULL,
    expiredate timestamp without time zone DEFAULT '1970-01-01 00:00:00+08'::timestamp with time zone
);


ALTER TABLE public.ovpnclients OWNER TO mgmt;

--
-- Name: ovpnclients ovpnclients_un; Type: CONSTRAINT; Schema: public; Owner: mgmt
--

ALTER TABLE ONLY public.ovpnclients
    ADD CONSTRAINT ovpnclients_un UNIQUE (cn);


--
-- PostgreSQL database dump complete
--
