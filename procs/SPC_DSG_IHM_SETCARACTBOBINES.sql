SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Modification des paramètres de toutes les bobines contenues dans une allée
-- @p_AdrSys 
-- @p_AdrBase
-- @p_AdrSousBase : Clé d'adressage
-- @p_IdFournisseur : Fournisseur
-- @p_IdGrammage : Grammage
-- @p_IdSensEnroulement : Sens d'enroulement
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DSG_IHM_SETCARACTBOBINES]
	@p_AdrSys BIGINT,
	@p_AdrBase BIGINT,
	@p_AdrSousBase BIGINT,
	@p_IdFournisseur INT,
	@p_IdGrammage INT,
	@p_IdSensEnroulement INT
AS
BEGIN
-- Déclaration des constantes
DECLARE @CODE_OK				 INT = 0,
		@CODE_KO_DEPOSENCOURS	 INT = -1488, -- Modification Interdite : Dépose en Cours vers cette allée
		@CODE_KO_PRISEENCOURS	 INT = -1489,  -- Modification Interdite : Prise en Cours depuis cette allée
		@CODE_KO_EVACRECPENCOURS INT = -1490, -- Modification Interdite : Entrée Réception En Cours ou En Attente	
		@CODE_KO_FOURNISSEURINCONNU	INT = -1491, -- Modification Interdite : Fournisseur Inconnu
		@CODE_KO_GRAMMAGEINCONNU	INT = -1495, -- Modification Interdite : Grammage Inconnu
		@CODE_KO_SENSINCONNU	INT = -1492 -- Modification Interdite : Sens Inconnu

DECLARE @ACT_DEPOSE INT = 4,
		@ACT_PRISE  INT = 2
DECLARE @ADRSYS_CVYRECP BIGINT = 65793,
		@ADRBASE_CVYRECP BIGINT = 144116291882516737,
		@ADRSOUSBASE_CVYRECP BIGINT = 65793	
DECLARE @TRC_CHGETAT INT = 5
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID),
		@moniteur VARCHAR(128) = 'Gest.IHM'

-- Déclaration des variables
DECLARE @Retour INT = @CODE_OK

DECLARE @IdBobine INT
DECLARE @Trace VARCHAR(500)
DECLARE @CodeFournisseur NCHAR(2),		
		@PapeterieFournisseur VARCHAR(100),
		@PaysFournisseur VARCHAR(20),
		@TarifFournisseur SMALLINT,
		@CodeGrammage numeric(5,2),
		@SensEnroulement INT


SET @Trace = 'Entrée : @p_AdrBase = ' + ISNULL(CONVERT(VARCHAR, @p_AdrBase), 'NULL')
						+' , @p_IdFournisseur = '+ ISNULL(CONVERT(VARCHAR, @p_IdFournisseur), 'NULL')
						+' , @p_IdGrammage = '+ ISNULL(CONVERT(VARCHAR, @p_IdGrammage), 'NULL')
						+' , @p_IdSensEnroulement = '+ ISNULL(CONVERT(VARCHAR, @p_IdSensEnroulement), 'NULL')
SET @Trace = @procStock + '/' + @Trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace


-- Vérification s'il existe une mission de dépose vers cette allée
IF EXISTS (SELECT 1 FROM INT_TACHE_MISSION
				WHERE TAC_IDACTION = @ACT_DEPOSE
					AND TAC_IDSYSTEMEEXECUTION = @p_AdrSys
					AND TAC_IDBASEEXECUTION = @p_AdrBase
					AND TAC_IDSOUSBASEEXECUTION = @p_AdrSousBase)
BEGIN
	SET @Retour = @CODE_KO_DEPOSENCOURS
END

-- Vérification s'il existe une mission de prise (avant prise depuis cette allée)
IF @Retour = @CODE_OK
BEGIN
	IF EXISTS (SELECT 1 FROM INT_TACHE_MISSION
					WHERE TAC_IDACTION = @ACT_PRISE
						AND TAC_IDSYSTEMEEXECUTION = @p_AdrSys
						AND TAC_IDBASEEXECUTION = @p_AdrBase
						AND TAC_IDSOUSBASEEXECUTION = @p_AdrSousBase
						AND TAC_IDETATTACHE NOT IN (5,6))
	BEGIN
		SET @Retour = @CODE_KO_PRISEENCOURS
	END
END

-- Vérification s'il existe une mission d'évacuation du convoyeur de réception Avant Prise
-- ==> On ne peut pas prendre le risque que la mission ait été acceptée pour l'allée et qu'il n'y en ait pas d'autres
IF @Retour = @CODE_OK
BEGIN
	IF EXISTS (SELECT 1 FROM INT_TACHE_MISSION
					WHERE TAC_IDACTION = @ACT_PRISE
						AND TAC_IDSYSTEMEEXECUTION = @ADRSYS_CVYRECP
						AND TAC_IDBASEEXECUTION = @ADRBASE_CVYRECP
						AND TAC_IDSOUSBASEEXECUTION = @ADRSOUSBASE_CVYRECP
						AND TAC_IDETATTACHE NOT IN (5,6))
	BEGIN
		SET @Retour = @CODE_KO_EVACRECPENCOURS
	END
END

-----------------------------
-- Mise à jour Fournisseur --
-----------------------------
IF @p_IdFournisseur <> -1
BEGIN
	-- Si tout est OK, recherche des infos fournisseur associées au code
	SELECT @CodeFournisseur=SCF_CODE, @PapeterieFournisseur=SCF_IDTRADUCTION_PAPETERIE, @PaysFournisseur=SCF_IDTRADUCTION_PAYS,
				@TarifFournisseur=SCF_IDFOURNISSEUR
		FROM SPC_CHG_FOURNISSEUR
	WHERE SCF_IDFOURNISSEUR=@p_IdFournisseur
	IF @@ROWCOUNT = 0
	BEGIN
		SET @Retour = @CODE_KO_FOURNISSEURINCONNU
	END
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;

	IF @Retour = @CODE_OK
	BEGIN
		SET @Trace = @PROCSTOCK + ': IdFournisseur = ' + CONVERT(varchar, ISNULL(@p_IdFournisseur,-1))
								+ ', Base = ' + CONVERT(varchar, ISNULL (@p_AdrBase, -1))
		EXEC INT_ADDTRACESPECIFIQUE @moniteur, 'SUIVI', @Trace
		DECLARE c_Bobine CURSOR LOCAL FOR
			SELECT CHG_IDCHARGE
				FROM INT_CHARGE_VIVANTE
			WHERE CHG_IDSYSTEME = @p_AdrSys AND CHG_IDBASE = @p_AdrBase AND CHG_IDSOUSBASE = @p_AdrSousBase	
		OPEN c_Bobine
		FETCH NEXT FROM c_Bobine INTO @IdBobine
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE SPC_CHARGE_BOBINE 
				SET SCB_IDFOURNISSEUR = @p_IdFournisseur, SCB_VALORISATION = @TarifFournisseur
			WHERE SCB_IDCHARGE = @IdBobine

			IF @Retour = @CODE_OK
		 		EXEC @Retour = SPC_CHG_VALORISER @v_idcharge = @IdBobine

			FETCH NEXT FROM c_Bobine INTO @IdBobine
		END
		
		CLOSE c_Bobine
		DEALLOCATE c_Bobine
	END
END

-----------------------------
--   Mise à jour Grammage  --
-----------------------------
IF @p_IDGRAmmage <> -1
BEGIN
select * from SPC_CHARGE_BOBINE
-- Si tout est OK, recherche de la valeur de grammage associée au code
SELECT @CodeGrammage = SCG_CODE
	FROM SPC_CHG_GRAMMAGE
WHERE SPC_CHG_GRAMMAGE.SCG_CODE = @p_IdGrammage
IF @@ROWCOUNT = 0
BEGIN
	SET @Retour = @CODE_KO_GRAMMAGEINCONNU
END

-- Si pas de missions, recherche de toutes les bobines présentes dans l'allée
-- pour modifier son grammage
IF @Retour = @CODE_OK
BEGIN
	SET @Trace = @PROCSTOCK + ': IdGrammage = ' + CONVERT(varchar, ISNULL(@p_IdGrammage,-1))
							+ ', Base = ' + CONVERT(varchar, ISNULL (@p_AdrBase, -1))
	EXEC INT_ADDTRACESPECIFIQUE @moniteur, 'SUIVI', @Trace

	DECLARE c_Bobine CURSOR LOCAL FOR
		SELECT CHG_IDCHARGE
			FROM INT_CHARGE_VIVANTE
		WHERE CHG_IDSYSTEME = @p_AdrSys AND CHG_IDBASE = @p_AdrBase AND CHG_IDSOUSBASE = @p_AdrSousBase
	OPEN c_Bobine
	FETCH NEXT FROM c_Bobine INTO @IdBobine
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @CodeGrammage = SPC_CHG_GRAMMAGE.SCG_GRAMMAGE from SPC_CHG_GRAMMAGE where SPC_CHG_GRAMMAGE.SCG_CODE = @p_IdGrammage
		UPDATE SPC_CHARGE_BOBINE
			SET SCB_GRAMMAGE = @CodeGrammage
		WHERE SCB_IDCHARGE = @IdBobine
		SET @Retour = @@ERROR

		IF @Retour = @CODE_OK
		 		EXEC @Retour = SPC_CHG_VALORISER @v_idcharge = @IdBobine

		FETCH NEXT FROM c_Bobine INTO @IdBobine
	END
	
	CLOSE c_Bobine
	DEALLOCATE c_Bobine
END

END

-----------------------------
--   Mise à jour Sens Enroulement  --
-----------------------------
IF @p_IdSensEnroulement <> -1
BEGIN

-- Si tout est OK, recherche de la valeur de grammage associée au code
SELECT @SensEnroulement = SPC_CHG_SENSENROULEMENT.SSE_ORIENTATION
	FROM SPC_CHG_SENSENROULEMENT
WHERE SPC_CHG_SENSENROULEMENT.SSE_SENSENROULEMENT= @p_IdSensEnroulement
IF @@ROWCOUNT = 0
BEGIN
	SET @Retour = @CODE_KO_SENSINCONNU
END

-- Si pas de missions, recherche de toutes les bobines présentes dans l'allée
-- pour modifier son sens d'enroulement
IF @Retour = @CODE_OK
BEGIN
	SET @Trace = @PROCSTOCK + ': @SensEnroulement = ' + CONVERT(varchar, ISNULL(@SensEnroulement,-1))
							+ ', Base = ' + CONVERT(varchar, ISNULL (@p_AdrBase, -1))
	EXEC INT_ADDTRACESPECIFIQUE @moniteur, 'SUIVI', @Trace

	DECLARE c_Bobine CURSOR LOCAL FOR
		SELECT CHG_IDCHARGE
			FROM INT_CHARGE_VIVANTE
		WHERE CHG_IDSYSTEME = @p_AdrSys AND CHG_IDBASE = @p_AdrBase AND CHG_IDSOUSBASE = @p_AdrSousBase
	OPEN c_Bobine
	FETCH NEXT FROM c_Bobine INTO @IdBobine
	
	WHILE @@FETCH_STATUS = 0
	BEGIN		
		UPDATE CHARGE
			SET CHARGE.CHG_ORIENTATION = @SensEnroulement
		WHERE CHARGE.CHG_ID = @IdBobine
		SET @Retour = @@ERROR
		 
		 IF @Retour = @CODE_OK
		 		EXEC @Retour = SPC_CHG_VALORISER @v_idcharge = @IdBobine

		FETCH NEXT FROM c_Bobine INTO @IdBobine
	END
	
	CLOSE c_Bobine
	DEALLOCATE c_Bobine
END

END
RETURN @Retour

END
