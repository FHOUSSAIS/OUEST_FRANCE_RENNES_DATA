SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procedure		: SPV_AFFINECYCLIQUE
-- Paramètre d'entrée	: 
-- Paramètre de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_VIDE : Absence procédure stockée d'affinage spécifique
--			    @CODE_KO_INCORRECT : Affinage incorrect
--			    @CODE_KO_SQL : Erreur SQL
--			    @CODE_KO_ADR_INCONNUE : Adresse inconnue
-- Descriptif		: Affinage cyclique
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_AFFINECYCLIQUE]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_iag_idagv tinyint,
	@v_ord_idordre int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint

-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_EXECUTION tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_STOPPE tinyint,
	@DESC_AFFINAGE_ADRESSE tinyint,
	@DESC_AFFINAGE_TACHE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @AFFI_EXECUTION = 2
	SET @ETAT_STOPPE = 3
	SET @DESC_AFFINAGE_ADRESSE = 12
	SET @DESC_AFFINAGE_TACHE = 15

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO

	-- Vérification de l'existence d'une tâche à affiner
	DECLARE c_agv CURSOR LOCAL FOR SELECT DISTINCT IAG_ID FROM INFO_AGV, ORDRE_AGV, TACHE, ADRESSE WHERE IAG_OPERATIONNEL = 'O' AND IAG_MODE = 1 AND ORD_IDAGV = IAG_ID AND ORD_IDETAT = @ETAT_STOPPE AND ORD_DSCETAT IN (@DESC_AFFINAGE_ADRESSE, @DESC_AFFINAGE_TACHE)
		AND TAC_IDORDRE = ORD_IDORDRE AND TAC_IDETAT = @ETAT_STOPPE AND TAC_DSCETAT IN (@DESC_AFFINAGE_ADRESSE, @DESC_AFFINAGE_TACHE) AND TAC_AFFINAGEADR = @AFFI_EXECUTION AND ADR_SYSTEME = TAC_IDADRSYS AND ADR_BASE = TAC_IDADRBASE
		AND ADR_SOUSBASE = TAC_IDADRSSBASE AND ADR_TYPE = 0
	OPEN c_agv
	FETCH NEXT FROM c_agv INTO @v_iag_idagv
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		EXEC @v_status = SPV_AFFINEEXECUTION 1, @v_iag_idagv
		IF @v_error = 0
			SET @v_error = @@ERROR
		FETCH NEXT FROM c_agv INTO @v_iag_idagv
	END
	CLOSE c_agv
	DEALLOCATE c_agv
	-- Vérification de l'existence d'une adresse à affiner
	DECLARE c_agv CURSOR LOCAL FOR SELECT DISTINCT IAG_ID, ORD_IDORDRE FROM INFO_AGV, ORDRE_AGV, TACHE, ADRESSE WHERE IAG_OPERATIONNEL = 'O' AND IAG_MODE = 1 AND ORD_IDAGV = IAG_ID AND ORD_IDETAT = @ETAT_STOPPE AND ORD_DSCETAT IN (@DESC_AFFINAGE_ADRESSE, @DESC_AFFINAGE_TACHE)
		AND TAC_IDORDRE = ORD_IDORDRE AND TAC_IDETAT = @ETAT_STOPPE AND TAC_DSCETAT IN (@DESC_AFFINAGE_ADRESSE, @DESC_AFFINAGE_TACHE) AND ADR_SYSTEME = TAC_IDADRSYS AND ADR_BASE = TAC_IDADRBASE
		AND ADR_SOUSBASE = TAC_IDADRSSBASE AND ADR_TYPE = 1
	OPEN c_agv
	FETCH NEXT FROM c_agv INTO @v_iag_idagv, @v_ord_idordre
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		EXEC @v_status = SPV_AFFINEADRESSE 1, @v_iag_idagv, @v_ord_idordre
		IF @v_error = 0
			SET @v_error = @@ERROR
		FETCH NEXT FROM c_agv INTO @v_iag_idagv, @v_ord_idordre
	END
	CLOSE c_agv
	DEALLOCATE c_agv
	IF @v_status = @CODE_OK AND @v_error = 0
		SET @v_retour = @CODE_OK
	ELSE
		SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
	RETURN @v_retour

