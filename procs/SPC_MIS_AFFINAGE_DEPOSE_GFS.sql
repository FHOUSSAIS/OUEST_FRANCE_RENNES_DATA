SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Création de la procédure pour différencier prise et dépose
-- @v_iag_idagv               : Identifiant AGV
-- @v_tac_idtache             : identifiant de tache
-- @v_tac_idsystemeexecution  : systeme de base d'execution
-- @v_tac_idbaseexecution     : base d'execution
-- @v_tac_idsousbaseexecution : sous base d'éxecution
-- @v_tac_idsystemeaffinage   : systeme de base d'affinage
-- @v_tac_idbaseaffinage      :	base d'affinage
-- @v_tac_idsousbaseaffinage  :	sous base d'affinage
-- =============================================
CREATE PROCEDURE [dbo].[SPC_MIS_AFFINAGE_DEPOSE_GFS]
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
declare @ADR_IDBASE_RECEPTION   bigint,
		@ADR_IDBASE_DEC_DEMAC5	bigint,
		@ADR_IDBASE_DEC_DEMAC6	bigint,
		@ADR_IDSYS_DEFAUT		bigint,
		@ADR_IDSSBASE_DEFAUT	bigint

DECLARE @ACTION_PRISE TINYINT	
		
-- Déclaration des variables
declare @Retour int,
		@procStock varchar(128),
		@chaineTrace varchar(7500)
DECLARE @adr_idBasePrise bigint,
		@adr_idBaseTache BIGINT
DECLARE @IdBobine INT,
		@Laize SMALLINT,
		@Diametre SMALLINT,
		@CodeGrammage NUMERIC(4,1), 
		@IdFournisseur INT,
		@IdDmd INT,
		@DerouleurDmd TINYINT,
		@v_Error TINYINT,
		@IdFournisseurPref INT,
		@EtatLigneDEMACULAGE INT

-- Initialisation des constantes
set @CODE_OK = 0
set @CODE_KO = 1
set @CODE_KO_SPECIFIQUE = 20 

set @ADR_IDBASE_RECEPTION		= 144116291882516737
set @ADR_IDBASE_DEC_DEMAC5		= 360293472042811649
set @ADR_IDBASE_DEC_DEMAC6		= 360294571554439425

set @ADR_IDSYS_DEFAUT         = 65793
set @ADR_IDSSBASE_DEFAUT   = 65793

SET @ACTION_PRISE = 2

-- Initialisation des variables
set @Retour = @CODE_OK
set @procStock = 'SPC_MIS_AFFINAGE_DEPOSE_GFS'
set @adr_idBasePrise = NULL

declare @v_rack int = 0

-- Recherche si l'affinage touche une tache de prise ou de dépose
SELECT @adr_idBaseTache = TAC_IDBASEEXECUTION,
		@IdBobine = MIS_IDCHARGE, @IdDmd = MIS_DEMANDE
	FROM INT_TACHE_MISSION
INNER JOIN INT_MISSION_VIVANTE ON MIS_IDMISSION = TAC_IDMISSION
WHERE TAC_IDTACHE = @v_tac_idtache

SET @ChaineTrace = 'Entrée Affinage @v_iag_idagv = '+CONVERT(varchar,@v_iag_idagv)
						+ ', @v_tac_idtache= '+CONVERT(varchar,isnull(@v_tac_idtache,-1))
						+ ', @v_tac_idsystemeexecution= '+CONVERT(varchar,isnull(@v_tac_idsystemeexecution,-1))
						+ ', @v_tac_idbaseexecution= '+CONVERT(varchar,isnull(@v_tac_idbaseexecution,-1))
						+ ', @v_tac_idsousbaseexecution= '+CONVERT(varchar,isnull(@v_tac_idsousbaseexecution,-1))
						+ ', @v_tac_idsystemeaffinage= '+CONVERT(varchar,isnull(@v_tac_idsystemeaffinage,-1))
						+ ', @v_tac_idbaseaffinage= '+CONVERT(varchar,isnull(@v_tac_idbaseaffinage,-1))
						+ ', @v_tac_idsousbaseaffinage= '+CONVERT(varchar,isnull(@v_tac_idsousbaseaffinage,-1))
EXEC INT_ADDTRACESPECIFIQUE @procStock, 'DEBUG', @ChaineTrace

	-- ===============================================================
	-- AFFINAGE DE LA BASE STOCK DE MASSE SI PRISE CONVOYEUR RECEPTION
	-- ===============================================================
	-- Récupération Adresse de Prise
	select @adr_idBasePrise = PRISE.TAC_IDBASEEXECUTION
	from   INT_MISSION_VIVANTE
	join   INT_TACHE_MISSION PRISE on MIS_IDMISSION = PRISE.TAC_IDMISSION
	join   INT_TACHE_MISSION DEPOSE on MIS_IDMISSION = DEPOSE.TAC_IDMISSION
	where  PRISE.TAC_IDACTION = @ACTION_PRISE
	and    DEPOSE.TAC_IDTACHE = @v_tac_idtache

	if( @adr_idBasePrise = @ADR_IDBASE_RECEPTION ) AND @v_tac_idbaseaffinage IS NULL
	begin
		SET @ChaineTrace = 'Affinage Dépose Depuis Convoyeur de réception:'+CONVERT(varchar,@adr_idBaseTache)
		EXEC INT_ADDTRACESPECIFIQUE @procStock, 'DEBUG', @ChaineTrace

		EXEC @Retour = SPC_MIS_AFFINAGE_GETALLEESTOCKAGE	@v_iag_idagv               ,
															@v_tac_idtache             ,
															@v_tac_idsystemeexecution  OUTPUT,
															@v_tac_idbaseexecution     OUTPUT,
															@v_tac_idsousbaseexecution OUTPUT,
															@v_tac_idsystemeaffinage   OUTPUT,
															@v_tac_idbaseaffinage      OUTPUT,
															@v_tac_idsousbaseaffinage  OUTPUT
		
		/*Modification de la base d'execution en stock global si allée trouvée*/
		IF @Retour = @CODE_OK
				SELECT
					@v_tac_idsystemeexecution = INT_ADRESSE.ADR_IDSYSTEME,
					@v_tac_idbaseexecution = INT_ADRESSE.ADR_IDBASE,
					@v_tac_idsousbaseexecution = INT_ADRESSE.ADR_IDSOUSBASE
				FROM INT_ADRESSE
				WHERE INT_ADRESSE.ADR_IDTYPEMAGASIN = 3
				AND INT_ADRESSE.ADR_MAGASIN = 2
				AND ADR_COTE = 0
				AND INT_ADRESSE.ADR_IDSOUSBASE = 0

		SET @ChaineTrace = '@Retour:'+CONVERT(varchar,ISNULL(@Retour,-1))+';@IdBobine='+CONVERT(varchar,isnull(@IdBobine,-1))
							+ ';@v_tac_idbaseaffinage='+CONVERT(varchar,isnull(@v_tac_idbaseaffinage,-1))
		EXEC INT_ADDTRACESPECIFIQUE @procStock, 'DEBUG', @ChaineTrace
	end
	
	/*Envoi dans l'allée*/
	ELSE if EXISTS (select 1 from INT_ADRESSE where ADR_IDBASE = @v_tac_idbaseaffinage and ADR_IDTYPEMAGASIN = 5 and ADR_MAGASIN = 2)
	BEGIN
		SET @ChaineTrace = 'Affinage Dépose Envoi dans allée:'+CONVERT(varchar,@adr_idBaseTache)
		EXEC INT_ADDTRACESPECIFIQUE @procStock, 'DEBUG', @ChaineTrace
		/*Recherche d'une allée correspondant à notre besoin*/
		SELECT @v_rack = ADR_RACK from INT_ADRESSE
			where ADR_IDTYPEMAGASIN = 5 and ADR_MAGASIN = 2
			and ADR_IDSYSTEME = @v_tac_idsystemeaffinage and ADR_IDBASE = @v_tac_idbaseaffinage and ADR_IDSOUSBASE = @v_tac_idsousbaseaffinage

		SELECT @v_tac_idsystemeexecution = ADR_IDSYSTEME , @v_tac_idbaseexecution = ADR_IDBASE, @v_tac_idsousbaseexecution = ADR_IDSOUSBASE
			FROM INT_ADRESSE where ADR_IDTYPEMAGASIN = 3 and ADR_RACK = @v_rack and ADR_MAGASIN = 2
		if( @@ROWCOUNT = 0 )
		begin
			set @ChaineTrace = 'Recherche Base Dépose Fine : Dmd de Réorga : ' + CONVERT( varchar, isnull( @IdDmd, -1 ) )
			exec INT_ADDTRACESPECIFIQUE @procStock, 'DEBUG', @ChaineTrace
		end
		else
		begin
			set @Retour = @CODE_OK
		end
	END

SET @ChaineTrace = 'Sortie Affinage Agv:'+CONVERT(varchar,@v_iag_idagv)
	+ ';@v_tac_idbaseaffinage= '+CONVERT(varchar,isnull(@v_tac_idbaseaffinage,-1))
	+ ';@v_tac_idbaseexecution= '+CONVERT(varchar,isnull(@v_tac_idbaseexecution,-1))
	+ ';@Retour= '+CONVERT(varchar,isnull(@Retour,-1))
EXEC INT_ADDTRACESPECIFIQUE @procStock, 'DEBUG', @ChaineTrace


RETURN @Retour
END

