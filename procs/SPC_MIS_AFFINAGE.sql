SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Affinage des missions de prise / dépose
-- @v_iag_idagv               : Identifiant AGV
-- @v_tac_idtache             : identifiant de tache
-- @v_tac_idsystemeexecution  : systeme de base d'execution
-- @v_tac_idbaseexecution     : base d'execution
-- @v_tac_idsousbaseexecution : sous base d'éxecution
-- @v_tac_idsystemeaffinage   : systeme de base d'affinage
-- @v_tac_idbaseaffinage      :	base d'affinage
-- @v_tac_idsousbaseaffinage  :	sous base d'affinage
-- @v_tac_accesbase			  : 
-- =============================================
CREATE PROCEDURE [dbo].[SPC_MIS_AFFINAGE]
	@v_iag_idagv               tinyint,
	@v_tac_idtache             int,
	@v_tac_idsystemeexecution  bigint out,
	@v_tac_idbaseexecution     bigint out,
	@v_tac_idsousbaseexecution bigint out,
	@v_tac_idsystemeaffinage   bigint out,
	@v_tac_idbaseaffinage      bigint out,
	@v_tac_idsousbaseaffinage  bigint out,
	@v_tac_accesbase bit out
AS
BEGIN

-- Déclaration des constantes
declare @CODE_OK int,
		@CODE_KO int,
		@CODE_KO_SPECIFIQUE int
		
DECLARE @ACTION_PRISE TINYINT,
		@ACTION_DEPOSE TINYINT
				
-- Déclaration des variables
declare @Retour int,
		@procStock varchar(128),
		@chaineTrace varchar(7500)
DECLARE @adr_idBasePrise bigint,
		@adr_idBaseTache BIGINT
DECLARE @IdActionTache INT,
		@IdBobine INT,
		@Laize INT,
		@Diametre INT,
		@CodeGrammage NUMERIC(6,2),
		@IdFournisseur INT,
		@IdDmd VARCHAR(20),
		@DerouleurDmd TINYINT,
		@v_Error TINYINT,
		@IdFournisseurPref INT
DECLARE @TypeAgv INT		

-- Initialisation des constantes
set @CODE_OK = 0
set @CODE_KO = 1
set @CODE_KO_SPECIFIQUE = 20

SET @ACTION_PRISE  = 2
SET @ACTION_DEPOSE = 4

-- Initialisation des variables
set @Retour = @CODE_OK
set @procStock = 'SPC_MIS_AFFINAGE'
set @adr_idBasePrise = NULL

SET @ChaineTrace = 'Entrée Affinage Agv:'+CONVERT(varchar,@v_iag_idagv)
EXEC INT_ADDTRACESPECIFIQUE @procStock, 'DEBUG', @ChaineTrace

-- Recherche si l'affinage touche une tache de prise ou de dépose
SELECT @IdActionTache = TAC_IDACTION, @adr_idBaseTache = TAC_IDBASEEXECUTION,
		@IdBobine = MIS_IDCHARGE, @IdDmd = MIS_DEMANDE
	FROM INT_TACHE_MISSION
INNER JOIN INT_MISSION_VIVANTE ON MIS_IDMISSION = TAC_IDMISSION
WHERE TAC_IDTACHE = @v_tac_idtache

	IF @IdActionTache = @ACTION_PRISE 
		EXEC @Retour = dbo.SPC_MIS_AFFINAGE_PRISE_GFS @v_iag_idagv,
							@v_tac_idtache, @v_tac_idsystemeexecution out,
							@v_tac_idbaseexecution out, @v_tac_idsousbaseexecution out,
							@v_tac_idsystemeaffinage out, @v_tac_idbaseaffinage out,
							@v_tac_idsousbaseaffinage out
	ELSE IF @IdActionTache = @ACTION_DEPOSE 
		EXEC @Retour = dbo.SPC_MIS_AFFINAGE_DEPOSE_GFS @v_iag_idagv,
							@v_tac_idtache, @v_tac_idsystemeexecution out,
							@v_tac_idbaseexecution out, @v_tac_idsousbaseexecution out,
							@v_tac_idsystemeaffinage out, @v_tac_idbaseaffinage out,
							@v_tac_idsousbaseaffinage out		

SET @ChaineTrace = 'Sortie Affinage Agv:'+CONVERT(varchar,@v_iag_idagv)
	+' , @v_tac_idbaseaffinage : '+CONVERT(varchar,ISNULL(@v_tac_idbaseaffinage,-1))
	+' , @v_tac_idsousbaseaffinage : '+CONVERT(varchar,ISNULL(@v_tac_idsousbaseaffinage,-1))
	+' , @v_tac_idbaseexecution : '+CONVERT(varchar,ISNULL(@v_tac_idbaseexecution,-1))
	+' , @v_tac_idsousbaseexecution : '+CONVERT(varchar,ISNULL(@v_tac_idsousbaseexecution,-1))
	+' , @Retour : '+CONVERT(varchar,ISNULL(@Retour,-1))

EXEC INT_ADDTRACESPECIFIQUE @procStock, '[DBGMIS]', @ChaineTrace


RETURN @Retour

END

