SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_SETLONGUEURADRESSE]
	@v_adr_idsysteme bigint,
	@v_adr_idbase bigint,
	@v_adr_idsousbase bigint,
	@v_adr_niveau tinyint = NULL,
	@v_longueur_debut int,
	@v_longueur_fin int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_local bit,
	@v_transaction varchar(32),
	@v_error int,
	@v_retour int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_ADR_INCONNUE tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_INCORRECT = 11
	SELECT @CODE_KO_SQL = 13
	SELECT @CODE_KO_ADR_INCONNUE = 28

-- Initialisation des variables
	SELECT @v_transaction = 'SETLONGUEURADRESSE'
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SELECT @v_local = 0
	ELSE
	BEGIN
		SELECT @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de l'adresse et de la structure
	IF EXISTS (SELECT 1 FROM INT_ADRESSE WHERE ADR_IDSYSTEME = @v_adr_idsysteme AND ADR_IDBASE = @v_adr_idbase AND ADR_IDSOUSBASE = @v_adr_idsousbase)
		AND EXISTS (SELECT 1 FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
		AND ((STR_COUCHE = @v_adr_niveau AND @v_adr_niveau IS NOT NULL) OR (@v_adr_niveau IS NULL)))
	BEGIN
		IF @v_longueur_debut < @v_longueur_fin AND EXISTS (SELECT 1 FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
			AND ((STR_COUCHE = @v_adr_niveau AND @v_adr_niveau IS NOT NULL) OR (@v_adr_niveau IS NULL))
			AND STR_LONGUEUR_DEBUT_INITIALE <= @v_longueur_debut AND STR_LONGUEUR_FIN_INITIALE >= @v_longueur_fin)
		BEGIN
			UPDATE STRUCTURE SET STR_LONGUEUR_DEBUT_COURANTE = @v_longueur_debut, STR_LONGUEUR_FIN_COURANTE = @v_longueur_fin
				WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
				AND ((STR_COUCHE = @v_adr_niveau AND @v_adr_niveau IS NOT NULL) OR (@v_adr_niveau IS NULL))
			SELECT @v_error = @@ERROR
			IF @v_error = 0
				SELECT @v_retour = @CODE_OK
			ELSE
				SELECT @v_retour = @CODE_KO_SQL
		END
		ELSE
			SELECT @v_retour = @CODE_KO_INCORRECT		
	END
	ELSE
		SELECT @v_retour = @CODE_KO_ADR_INCONNUE
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour

