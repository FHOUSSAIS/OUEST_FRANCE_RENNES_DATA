SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procédure		: CFG_SOUSBASE
-- Paramètre d'entrées	: @v_bas_systeme : Système
--			  @v_bas_base : Base
--			  @v_bas_libelle : Libellé base
--			  @v_profondeur : Profondeur
--			  @v_niveau : Niveau
--			  @v_colonne : Colonne
--			  @v_lan_id : Identifiant langue
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des sous-bases
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_SOUSBASE]
	@v_bas_systeme bigint,
	@v_bas_base bigint,
	@v_bas_libelle varchar(8000),
	@v_profondeur tinyint,
	@v_niveau tinyint,
	@v_colonne tinyint,
	@v_lan_id varchar(3),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error smallint,
	@v_status int,
	@v_p tinyint,
	@v_n tinyint,
	@v_c tinyint,
	@v_lib_libelle varchar(8000),
	@v_adr_sousbase bigint,
	@v_adr_idtraduction int,
	@v_adr_type bit,
	@v_local bit

-- Déclaration des constantes d'états d'occupations
DECLARE
	@ETAT_VIDE tinyint

-- Définition des constantes
	SET @ETAT_VIDE = 1

-- Initialisation des variables
	SET @v_retour = 113
	SET @v_status = 0
	SET @v_error = 0

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN SOUSBASE
	END
	IF EXISTS (SELECT 1 FROM SYSTEME)
	BEGIN
		SELECT @v_p = CASE WHEN @v_profondeur >= 1 THEN 1 ELSE 0 END
		WHILE ((@v_p <= @v_profondeur) AND (@v_error = 0))
		BEGIN
			SELECT @v_n = CASE WHEN @v_niveau >= 1 THEN 1 ELSE 0 END
			WHILE ((@v_n <= @v_niveau) AND (@v_error = 0))
			BEGIN
				SELECT @v_c = CASE WHEN @v_colonne >= 1 THEN 1 ELSE 0 END
				WHILE ((@v_c <= @v_colonne) AND (@v_error = 0))
				BEGIN
					SELECT @v_adr_sousbase = dbo.INT_GETIDSOUSBASE(@v_p, @v_n, @v_c)
					IF NOT EXISTS (SELECT 1 FROM ADRESSE WHERE ADR_SYSTEME = @v_bas_systeme AND ADR_BASE = @v_bas_base
						AND ADR_SOUSBASE = @v_adr_sousbase)
					BEGIN
						SELECT @v_lib_libelle = @v_bas_libelle + '-' + CONVERT(varchar, @v_p) + '.' + CONVERT(varchar, @v_n) + '.' + CONVERT(varchar, @v_c)
						EXEC @v_error = LIB_TRADUCTION 0, @v_lan_id, @v_lib_libelle, @v_adr_idtraduction out
						IF @v_error = 0
						BEGIN
							SELECT @v_adr_type = CASE WHEN EXISTS (SELECT 1 FROM BASE WHERE BAS_SYSTEME = @v_bas_systeme AND BAS_BASE = @v_bas_base AND BAS_TYPE = 0) OR @v_p = 0 OR @v_n = 0 OR @v_c = 0 THEN 0 ELSE 1 END
							INSERT INTO ADRESSE (ADR_SYSTEME, ADR_BASE, ADR_SOUSBASE, ADR_PROFONDEUR, ADR_NIVEAU,
								ADR_COLONNE, ADR_TYPE, ADR_IDTRADUCTION, ADR_ETAT_OCCUPATION)
								VALUES (@v_bas_systeme, @v_bas_base, @v_adr_sousbase, @v_p, @v_n,
								@v_c, @v_adr_type, @v_adr_idtraduction, @ETAT_VIDE)
							SELECT @v_error = @@ERROR
						END
					END
					SELECT @v_c = @v_c + 1
				END
				SELECT @v_n = @v_n + 1
			END
			SELECT @v_p = @v_p + 1
		END
		IF @v_error = 0
		BEGIN
			IF ((@v_profondeur <> 0) AND (@v_niveau <> 0) AND (@v_colonne <> 0)) AND EXISTS (SELECT 1 FROM ADRESSE WHERE ADR_SYSTEME = @v_bas_systeme AND ADR_BASE = @v_bas_base AND ((ADR_PROFONDEUR > @v_profondeur)
				OR (ADR_NIVEAU > @v_niveau) OR (ADR_COLONNE >= @v_colonne)))
			BEGIN
				DECLARE c_adresse CURSOR LOCAL FOR SELECT ADR_SOUSBASE, ADR_IDTRADUCTION FROM ADRESSE
					WHERE ADR_SYSTEME = @v_bas_systeme AND ADR_BASE = @v_bas_base AND ((ADR_PROFONDEUR > @v_profondeur) OR (ADR_NIVEAU > @v_niveau)
					OR (ADR_COLONNE > @v_colonne))
				OPEN c_adresse
				FETCH NEXT FROM c_adresse INTO @v_adr_sousbase, @v_adr_idtraduction
				SELECT @v_status
				WHILE ((@@FETCH_STATUS = 0) AND (@v_status = 0) AND (@v_error = 0))
				BEGIN
					EXEC @v_status = CFG_ADRESSE 2, NULL, @v_bas_systeme, @v_bas_base, @v_adr_sousbase, @v_adr_idtraduction, NULL, NULL, @v_retour out
					SET @v_error = @@ERROR
					FETCH NEXT FROM c_adresse INTO @v_adr_sousbase, @v_adr_idtraduction
				END
				IF ((@v_status = 0) AND (@v_error = 0))
					SELECT @v_retour = 0
			END
			ELSE
				SELECT @v_retour = 0
		END
	END
	ELSE
		SELECT @v_retour = 1284
	IF @v_local = 1
	BEGIN
		IF ((@v_error = 0) AND (@v_retour = 0))
			COMMIT TRAN SOUSBASE
		ELSE
			ROLLBACK TRAN SOUSBASE
	END
	RETURN @v_error


