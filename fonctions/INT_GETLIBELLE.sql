SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

CREATE FUNCTION [dbo].[INT_GETLIBELLE] (@v_tra_id int, @v_lan_id varchar(3))
	RETURNS varchar(8000)
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_lib_libelle varchar(8000),
	@v_par_valeur varchar(128)

-- Déclaration des constantes de traduction
DECLARE
	@TRAD_INCONNUE int

-- Définition des constantes
	SELECT @TRAD_INCONNUE = 788

	IF @v_tra_id IS NOT NULL
	BEGIN
		SELECT @v_par_valeur = PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'LANGUE'
		IF EXISTS (SELECT 1 FROM TRADUCTION WHERE TRA_ID = @v_tra_id)
			SELECT @v_lib_libelle = CASE WHEN ISNULL(LIB_LIBELLE, '') = '' AND @v_lan_id <> @v_par_valeur THEN dbo.INT_GETLIBELLE(@v_tra_id, @v_par_valeur)
				ELSE LIB_LIBELLE END FROM LIBELLE WHERE LIB_TRADUCTION = @v_tra_id
				AND LIB_LANGUE = CASE WHEN NOT EXISTS (SELECT 1 FROM LANGUE WHERE LAN_ID = @v_lan_id AND LAN_ACTIF = 1)
				THEN @v_par_valeur ELSE @v_lan_id END
		ELSE
			SELECT @v_lib_libelle = dbo.INT_GETLIBELLE(@TRAD_INCONNUE, @v_lan_id)
	END
	ELSE
		SELECT @v_lib_libelle = NULL
	RETURN @v_lib_libelle

END


