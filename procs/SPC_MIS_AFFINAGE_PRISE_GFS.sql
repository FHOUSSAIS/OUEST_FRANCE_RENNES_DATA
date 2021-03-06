SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Author:		G.MASSARD
-- Create date: 07/07/2010
-- Description:	Création de la procédure en phase 2 pour différencier les GFS des GBH
-- =============================================
CREATE PROCEDURE [dbo].[SPC_MIS_AFFINAGE_PRISE_GFS]
	@v_iag_idagv               tinyint,
	@v_tac_idtache             int,
	@v_tac_idsystemeexecution  bigint out,
	@v_tac_idbaseexecution     bigint out,
	@v_tac_idsousbaseexecution bigint out,
	@v_tac_idsystemeaffinage   bigint out,
	@v_tac_idbaseaffinage      bigint out,
	@v_tac_idsousbaseaffinage  bigint out
	
AS
BEGIN

-- Déclaration des constantes
declare @CODE_OK int,
		@CODE_KO int,
		@CODE_KO_SPECIFIQUE int 
		
DECLARE @ADR_IDBASE_STK_MASSE BIGINT
		
-- Déclaration des variables
declare @Retour int,
		@procStock varchar(128),
		@chaineTrace varchar(7500)
DECLARE @adr_idBaseTache BIGINT

DECLARE @Laize SMALLINT,
		@Diametre SMALLINT,
		@CodeGrammage NUMERIC(4,1), 
		@IdFournisseur INT,
		@IdDmd INT,
		@DerouleurDmd TINYINT,
		@v_Error TINYINT,
		@IdFournisseurPref INT

-- Initialisation des constantes
set @CODE_OK = 0
set @CODE_KO = 1
set @CODE_KO_SPECIFIQUE = 20 -- GMA240610

SET @ADR_IDBASE_STK_MASSE		 = 216173881625411584

-- Initialisation des variables
set @Retour = @CODE_OK
set @procStock = 'SPC_MIS_AFFINAGE_PRISE_GFS'

SET @ChaineTrace = 'Affinage Agv:'+CONVERT(varchar,@v_iag_idagv)
--EXEC SPC_ADDTRACESPECIFIQUE @procStock, '[DBGMIS]', @ChaineTrace -- 2.01

-- Recherche si l'affinage touche une tache de prise ou de dépose
SELECT @adr_idBaseTache = TAC_IDBASEEXECUTION, @IdDmd = MIS_DEMANDE
	FROM INT_TACHE_MISSION
INNER JOIN INT_MISSION_VIVANTE ON MIS_IDMISSION = TAC_IDMISSION
WHERE TAC_IDTACHE = @v_tac_idtache

	SET @ChaineTrace = @ChaineTrace+',Affinage Prise:'+CONVERT(varchar,@adr_idBaseTache) -- 2.01
	EXEC INT_ADDTRACESPECIFIQUE @procStock, '[DBGMIS]', @ChaineTrace
	-- ===============================
	-- AFFINAGE DE LA BASE STOCK_MASSE
	-- ===============================
	IF @adr_idBaseTache = @ADR_IDBASE_STK_MASSE
	BEGIN
		-- Recherche des informations de la bobine à déstocker dans la demande associée à la mission
		SELECT @Laize = SDA_LAIZE, @Diametre = SDA_DIAMETRE, @CodeGrammage = SDA_GRAMMAGE, 
				@IdFournisseur = SDA_IDFOURNISSEUR, @DerouleurDmd = SDN_DEROULEUR
			FROM SPC_DMD_ALIMENTATIONNOHAB
		WHERE SDA_ID = @IdDmd
		
		EXEC @retour = SPC_STK_GETDESTOCKAGEFOURNISSEUR @IdFournisseur, @DerouleurDmd, @Laize, 
												@Diametre, @CodeGrammage, @IdDmd,
												@v_tac_idsystemeexecution OUT,
												@v_tac_idbaseexecution OUT,
												@v_tac_idsousbaseexecution OUT,
												@v_Error OUT,
												@IdFournisseurPref OUT
		SET @ChaineTrace = 'Prise Stock Masse, @retour=' + CONVERT(varchar,@retour)+'base='+convert(varchar,@v_tac_idbaseexecution)
		EXEC INT_ADDTRACESPECIFIQUE @procStock, '[DBGMIS]', @ChaineTrace 
	END

RETURN @Retour

END

