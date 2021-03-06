SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Recherche d'une allée de stockage
-- @v_IdBobine : Identifiant Bobine
-- @v_SysAllee  : systeme de base d'execution
-- @v_BaseAllee : Idbase d'execution
-- @v_SousBaseAllee  : Sous base d'execution
-- @v_IdBobine : Identifiant Bobine
-- @v_SysAllee  : systeme de base d'affinage
-- @v_BaseAllee : Idbase d'affinage
-- @v_SousBaseAllee  : Sous base d'affinage
-- =============================================
CREATE PROCEDURE [dbo].[SPC_MIS_AFFINAGE_GETALLEESTOCKAGE] 
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
-----------------------------
DECLARE
		@CODE_OK tinyint,
		@CODE_KO tinyint,
		@CODE_KO_STK_PLEIN tinyint
DECLARE @ALLEE_OCCUPEE TINYINT,
		@ALLEE_VIDE TINYINT,
		@ZONE_STOCK TINYINT,
		@MAGASIN_STOCK_DE_MASSE TINYINT,
		@ACT_DEPOSE TINYINT,
		--@TRC_PRISE TINYINT,
		--@TRC_DEPOSE TINYINT,
		@TRC_PRISE VARCHAR(10),
		@TRC_DEPOSE VARCHAR(10),
		@ACT_ATTENTE TINYINT

-- Déclaration des variables
----------------------------
DECLARE @v_transaction varchar(32),
		@v_local bit,
		@v_retour INT,
		@v_Error INT
DECLARE @IdDiametre INT,
		@IdLaize INT,
		@CodeGrammage NUMERIC(5,2),
		@IdFournisseur INT,
		@Capacite INT,
		@Laize INT,
		@Diametre INT,
		@NbAlleesEntamees INT,
		@NbMissionEnCours INT,
		@ChaineTrace VARCHAR(8000),
		@DerniereAction VARCHAR(20),
		@nbPlaceDispo int,
		@nbMissionReorga int,
		@IdBobine int

-- Initialisation des constantes
-----------------------------------------
SET @CODE_OK = 0
SET @CODE_KO = 1
SET @CODE_KO_STK_PLEIN = 10

SET @ALLEE_VIDE		= 1
SET @ALLEE_OCCUPEE	= 2
SET @ZONE_STOCK		= 3
SET @MAGASIN_STOCK_DE_MASSE = 2

SET @ACT_ATTENTE = 1
SET @ACT_DEPOSE = 4
SET @TRC_DEPOSE = '4;0%'
SET @TRC_PRISE	= '2;0%'

-- Initialisation des variables
-------------------------------
set @v_transaction = 'SPC_STK_GETALLEESTOCKAGE'
SET @v_retour = @CODE_KO_STK_PLEIN
SET	@v_tac_idsystemeaffinage   = NULL
SET	@v_tac_idbaseaffinage      = NULL
SET	@v_tac_idsousbaseaffinage  = NULL

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

-- Gestion des ouvertures de transactions
-----------------------------------------
/*	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END*/	

-- Recherche si l'affinage touche une tache de prise ou de dépose
SELECT @IdBobine = MIS_IDCHARGE
	FROM INT_TACHE_MISSION
INNER JOIN INT_MISSION_VIVANTE ON MIS_IDMISSION = TAC_IDMISSION
WHERE TAC_IDTACHE = @v_tac_idtache

-- Recherche des informations du type de la bobine à stocker
------------------------------------------------------------
SELECT @IdDiametre = SCB_DIAMETRE, @IdLaize = SCB_LAIZE,
	   @CodeGrammage = SCB_GRAMMAGE, @IdFournisseur = SCB_IDFOURNISSEUR
FROM SPC_CHARGE_BOBINE
WHERE SCB_IdCharge = @IdBobine
SET @v_retour = @@ERROR

	SET @ChaineTrace = 'Bobine='+CONVERT(varchar,isnull(@IdBobine,0))+',Diametre='+CONVERT(varchar,isnull(@IdDiametre,0))
					+',Laize='+CONVERT(varchar,isnull(@IdLaize,0))+',Grammage='+CONVERT(varchar,isnull(@CodeGrammage,0))
					+',Fournisseur='+CONVERT(varchar,isnull(@IdFournisseur,0))
					+',SysAllee='+CONVERT(varchar,isnull(@v_tac_idsystemeaffinage,-1))
	EXEC INT_ADDTRACESPECIFIQUE @v_transaction, 'DEBUG', @ChaineTrace
	
-- Combien y a t il d'allées contenant ce type de bobines et autorisées en dépose ?
-- Et avec de la place
-----------------------------------------------------------------------------------
SELECT @NbAlleesEntamees = COUNT(*) FROM INT_ADRESSE ADR_DEP
inner join INT_ADRESSE DEC_DEP on  ADR_DEP.ADR_MAGASIN = DEC_DEP.ADR_MAGASIN
									AND ADR_DEP.ADR_COTE = DEC_DEP.ADR_COTE
									AND ADR_DEP.ADR_RACK = DEC_DEP.ADR_RACK
WHERE  ADR_DEP.ADR_AUTORISATIONDEPOSE = 1
		AND ADR_DEP.ADR_VERIFICATION = 0 -- Allée Contrôle OK
		AND ADR_DEP.ADR_IDTYPEMAGASIN = @ZONE_STOCK -- Stock
		AND ADR_DEP.ADR_MAGASIN = @MAGASIN_STOCK_DE_MASSE -- Stock de Masse
		AND ADR_DEP.ADR_IDSOUSBASE > 0 -- Adresse Fine
		AND DEC_DEP.ADR_IDTYPEMAGASIN = 5
		AND (dbo.INT_GETSTOCKABILITE (ADR_DEP.ADR_IDSYSTEME, ADR_DEP.ADR_IDBASE, ADR_DEP.ADR_IDSOUSBASE , 1 , NULL, @IdBobine, NULL)) > 0
		AND (dbo.INT_GETCAPACITE (ADR_DEP.ADR_IDSYSTEME, ADR_DEP.ADR_IDBASE, ADR_DEP.ADR_IDSOUSBASE, 1, NULL, @IdLaize, @IdDiametre, @IdDiametre, NULL, NULL)) > 0
		AND NOT EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME=ADR_DEP.ADR_IDSYSTEME 
										AND CHG_IDBASE = ADR_DEP.ADR_IDBASE 
										AND CHG_IDSOUSBASE = ADR_DEP.ADR_IDSOUSBASE 
										AND CHG_CONTROLE=1) 
		AND EXISTS (SELECT 1 FROM SPC_CHARGE_BOBINE
					inner join INT_CHARGE_VIVANTE on SCB_IDCHARGE = CHG_IDCHARGE
					WHERE CHG_IDSYSTEME = ADR_DEP.ADR_IDSYSTEME
										AND CHG_IDBASE = ADR_DEP.ADR_IDBASE
										AND CHG_IDSOUSBASE = ADR_DEP.ADR_IDSOUSBASE
										AND SCB_LAIZE = @IdLaize 
										AND SCB_DIAMETRE = @IdDiametre
										AND SCB_IDFOURNISSEUR = @IdFournisseur
										AND SCB_GRAMMAGE = @CodeGrammage)
		and not exists( select	1 from INT_MISSION_VIVANTE join SPC_DMD_REORGA_STOCK_GENERAL on SDG_IDDEMANDE = MIS_DEMANDE
						where SDG_IDSYSTEME_DEPOSE = ADR_DEP.ADR_IDSYSTEME and SDG_IDBASE_DEPOSE = ADR_DEP.ADR_IDBASE and SDG_IDSOUSBASE_DEPOSE = ADR_DEP.ADR_IDSOUSBASE
						and MIS_IDETATMISSION in ( 1, 2, 3, 4 ) )
SET @v_retour = @@ERROR	

	SET @ChaineTrace = @ChaineTrace+',@NbAlleesEntamees='+CONVERT(varchar,@NbAlleesEntamees)
	EXEC INT_ADDTRACESPECIFIQUE @v_transaction, 'DEBUG', @ChaineTrace

-- S'il n'y a qu'une seule allée de ce type
-- Et que la dernière action dans l'allée est une dépose
-- => On reste dans cette allée
IF @v_retour = @CODE_OK AND @NbAlleesEntamees = 1
BEGIN
	SELECT TOP 1 @v_tac_idsystemeaffinage = DEC_DEP.ADR_IDSYSTEME, @v_tac_idbaseaffinage = DEC_DEP.ADR_IDBASE,
				@v_tac_idsousbaseaffinage = DEC_DEP.ADR_IDSOUSBASE, @DerniereAction = TMI_DscTrc,
				@v_tac_idsystemeexecution = ADR_DEP.ADR_IDSYSTEME,@v_tac_idbaseexecution = ADR_DEP.ADR_IDBASE
				,@v_tac_idsousbaseexecution = ADR_DEP.ADR_IDSOUSBASE
				--,@nbPlaceDispo = dbo.SPC_STK_GETEMPLACEMENTSVIDES (@IdLaize, @IdDiametre, ADR_DEP.ADR_IDSYSTEME, ADR_DEP.ADR_IDBASE, ADR_DEP.ADR_IDSOUSBASE)
				FROM INT_ADRESSE ADR_DEP
				inner join INT_ADRESSE DEC_DEP on  ADR_DEP.ADR_MAGASIN = DEC_DEP.ADR_MAGASIN
												AND ADR_DEP.ADR_COTE = DEC_DEP.ADR_COTE
												AND ADR_DEP.ADR_RACK = DEC_DEP.ADR_RACK
				INNER JOIN TRACE_MISSION ON TMI_AdrSys = ADR_DEP.ADR_IDSYSTEME
										AND TMI_AdrBase = ADR_DEP.ADR_IDBASE
										AND TMI_AdrSsBase = ADR_DEP.ADR_IDSOUSBASE
	WHERE  ADR_DEP.ADR_AUTORISATIONDEPOSE = 1
			AND ADR_DEP.ADR_VERIFICATION = 0 -- Allée Contrôle OK
			AND ADR_DEP.ADR_IDTYPEMAGASIN = @ZONE_STOCK -- Stock
			AND ADR_DEP.ADR_MAGASIN = @MAGASIN_STOCK_DE_MASSE -- Stock de Masse
			AND ADR_DEP.ADR_IDSOUSBASE > 0 -- Adresse Fine
			AND DEC_DEP.ADR_IDTYPEMAGASIN = 5
			AND (dbo.INT_GETSTOCKABILITE (ADR_DEP.ADR_IDSYSTEME, ADR_DEP.ADR_IDBASE, ADR_DEP.ADR_IDSOUSBASE , 1 , NULL, @IdBobine, NULL)) > 0
			AND (dbo.INT_GETCAPACITE (ADR_DEP.ADR_IDSYSTEME, ADR_DEP.ADR_IDBASE, ADR_DEP.ADR_IDSOUSBASE, 1, NULL, @IdLaize, @IdDiametre, @IdDiametre, NULL, NULL)) > 0
			AND NOT EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME=ADR_DEP.ADR_IDSYSTEME 
											AND CHG_IDBASE = ADR_DEP.ADR_IDBASE 
											AND CHG_IDSOUSBASE = ADR_DEP.ADR_IDSOUSBASE 
											AND CHG_CONTROLE=1) 
			AND EXISTS (SELECT 1 FROM SPC_CHARGE_BOBINE 
						inner join INT_CHARGE_VIVANTE  on SCB_IDCHARGE = CHG_IDCHARGE
						inner join SPC_CHG_DIAMETRE on CHG_LARGEUR = SCD_DIAMETRE
						WHERE CHG_IDSYSTEME = ADR_DEP.ADR_IDSYSTEME
											AND CHG_IDBASE = ADR_DEP.ADR_IDBASE
											AND CHG_IDSOUSBASE = ADR_DEP.ADR_IDSOUSBASE
											AND SCB_LAIZE = @IdLaize 
											AND SCD_DIAMETRE = @IdDiametre
											AND SCB_IDFOURNISSEUR = @IdFournisseur
											AND SCB_GRAMMAGE = @CodeGrammage)
			AND (TMI_DscTrc LIKE @TRC_PRISE OR TMI_DscTrc LIKE @TRC_DEPOSE)
			and not exists( select	1 from INT_MISSION_VIVANTE join SPC_DMD_REORGA_STOCK_GENERAL  on SDG_IDDEMANDE = MIS_DEMANDE
						where SDG_IDSYSTEME_DEPOSE = ADR_DEP.ADR_IDSYSTEME and SDG_IDBASE_DEPOSE = ADR_DEP.ADR_IDBASE and SDG_IDSOUSBASE_DEPOSE = ADR_DEP.ADR_IDSOUSBASE
						and MIS_IDETATMISSION in ( 1, 2, 3, 4 ) )
	ORDER BY TMI_ID DESC
	SET @v_retour = @@ERROR	

	SET @ChaineTrace = '@DerniereAction='+CONVERT(varchar,@DerniereAction)
	EXEC INT_ADDTRACESPECIFIQUE @v_transaction, 'DEBUG', @ChaineTrace

	--IF @DerniereAction <> @TRC_DEPOSE
	IF @DerniereAction NOT LIKE @TRC_DEPOSE
	BEGIN
		SET @v_tac_idsystemeaffinage = NULL
		SET @v_tac_idbaseaffinage = NULL
		SET @v_tac_idsousbaseaffinage = NULL
	END
END

-- Combien y a t il d'allées vides choisies pour ce type de bobines et autorisées en dépose ?
---------------------------------------------------------------------------------------------
IF @v_retour = @CODE_OK AND @v_tac_idsystemeaffinage IS NULL
BEGIN
	SELECT TOP 1 @v_tac_idsystemeaffinage = DEC_DEP.ADR_IDSYSTEME, @v_tac_idbaseaffinage = DEC_DEP.ADR_IDBASE,@v_tac_idsousbaseaffinage = DEC_DEP.ADR_IDSOUSBASE,
				 @v_tac_idsystemeexecution = ADR_DEP.ADR_IDSYSTEME,@v_tac_idbaseexecution = ADR_DEP.ADR_IDBASE,@v_tac_idsousbaseexecution = ADR_DEP.ADR_IDSOUSBASE
				FROM MISSION
		INNER JOIN SPC_CHARGE_BOBINE ON SCB_IDCHARGE = MIS_IdCharge
		INNER JOIN TACHE ON TAC_IdMission = MIS_IdMission
		INNER JOIN ASSOCIATION_TACHE_ACTION_TACHE ON TAC_IdTache = ATA_IdTache
		INNER JOIN INT_ADRESSE ADR_DEP ON ADR_DEP.ADR_IDSYSTEME = TAC_IdAdrSys AND ADR_DEP.ADR_IDBASE = TAC_IdAdrBase AND ADR_DEP.ADR_IDSOUSBASE = TAC_IdAdrssBase
		INNER JOIN BASE ON ADR_DEP.ADR_IDSYSTEME = BAS_SYSTEME AND ADR_DEP.ADR_IDBASE = BAS_BASE
		LEFT OUTER JOIN SPC_ADRESSE_STOCK_GENERAL on SAG_IDSYSTEME = ADR_DEP.ADR_IDSYSTEME and SAG_IDBASE = ADR_DEP.ADR_IDBASE and SAG_IDSOUSBASE = ADR_DEP.ADR_IDSOUSBASE
		inner join INT_ADRESSE DEC_DEP on  ADR_DEP.ADR_MAGASIN = DEC_DEP.ADR_MAGASIN
									AND ADR_DEP.ADR_COTE = DEC_DEP.ADR_COTE
									AND ADR_DEP.ADR_RACK = DEC_DEP.ADR_RACK
	WHERE ((SAG_LAIZE = @IdLaize OR SAG_LAIZE IS NULL) -- Vérif des réservations
				AND (SAG_DIAMETRE = @IdDiametre OR SAG_DIAMETRE IS NULL)
				AND (SAG_IDFOURNISSEUR = @IdFournisseur OR SAG_IDFOURNISSEUR IS NULL)
				AND (SAG_GRAMMAGE = @CodeGrammage OR SAG_GRAMMAGE IS NULL)
				AND NOT (SAG_LAIZE IS NULL AND SAG_DIAMETRE IS NULL AND SAG_IDFOURNISSEUR IS NULL AND SAG_GRAMMAGE IS NULL))
		AND ADR_DEP.ADR_IDETAT_OCCUPATION = @ALLEE_VIDE
		AND ADR_DEP.ADR_IDSOUSBASE > 0
		AND ATA_IdAction in (@ACT_DEPOSE, @ACT_ATTENTE)
		AND ADR_DEP.ADR_VERIFICATION   = 0
		AND ADR_DEP.ADR_AUTORISATIONDEPOSE = 1
		AND BAS_TYPE_MAGASIN = @ZONE_STOCK
		AND BAS_MAGASIN = @MAGASIN_STOCK_DE_MASSE
		AND DEC_DEP.ADR_IDTYPEMAGASIN = 5
	IF @v_tac_idsystemeaffinage IS NOT NULL
	begin
		SET @v_retour = @CODE_OK
	end
	
	SET @ChaineTrace = '@v_BaseAllee='+CONVERT(varchar,@v_tac_idbaseaffinage)+',@NbAlleesEntamees='+CONVERT(varchar,@NbAlleesEntamees)
					+',@v_retour='+CONVERT(varchar,@v_retour)
	EXEC INT_ADDTRACESPECIFIQUE @v_transaction, 'DEBUG', @ChaineTrace
		
	IF @v_retour = @CODE_OK AND @NbAlleesEntamees <= 1 AND @v_tac_idsystemeaffinage IS NULL
	begin
		SET @v_retour = @CODE_KO_STK_PLEIN
	end
END

-- 1. Recherche dans ces allées
--		+ celles avec de la place
--	=> On prend l'allée où est stockée la bobine la + jeune
-----------------------------------------------------------
IF (@v_retour = @CODE_OK) and (@NbAlleesEntamees > 1)
BEGIN
	SET @ChaineTrace = 'Allée entamée'
	EXEC INT_ADDTRACESPECIFIQUE @v_transaction, 'DEBUG', @ChaineTrace

	SET @v_retour = @CODE_KO_STK_PLEIN
	SELECT TOP 1 @v_tac_idsystemeaffinage = DEC_DEP.ADR_IDSYSTEME, @v_tac_idbaseaffinage = DEC_DEP.ADR_IDBASE,
			@v_tac_idsousbaseaffinage = DEC_DEP.ADR_IDSOUSBASE, @v_tac_idsystemeexecution = ADR_DEP.ADR_IDSYSTEME,@v_tac_idbaseexecution = ADR_DEP.ADR_IDBASE,@v_tac_idsousbaseexecution = ADR_DEP.ADR_IDSOUSBASE
		FROM INT_ADRESSE ADR_DEP
		INNER JOIN INT_CHARGE_VIVANTE ON CHG_IDSYSTEME= ADR_DEP.ADR_IDSYSTEME
							AND CHG_IDBASE = ADR_DEP.ADR_IDBASE
							AND CHG_IDSOUSBASE = ADR_DEP.ADR_IDSOUSBASE
		INNER JOIN SPC_CHARGE_BOBINE ON CHG_IDCHARGE =  SCB_IDCHARGE
		LEFT OUTER JOIN SPC_ADRESSE_STOCK_GENERAL on SAG_IDSYSTEME = ADR_DEP.ADR_IDSYSTEME and SAG_IDBASE = ADR_DEP.ADR_IDBASE and SAG_IDSOUSBASE = ADR_DEP.ADR_IDSOUSBASE
		inner join INT_ADRESSE DEC_DEP on  ADR_DEP.ADR_MAGASIN = DEC_DEP.ADR_MAGASIN
									AND ADR_DEP.ADR_COTE = DEC_DEP.ADR_COTE
									AND ADR_DEP.ADR_RACK = DEC_DEP.ADR_RACK
	WHERE ADR_DEP.ADR_AUTORISATIONDEPOSE = 1
		AND ADR_DEP.ADR_VERIFICATION = 0 -- Allée Contrôle OK
		AND (dbo.INT_GETSTOCKABILITE (ADR_DEP.ADR_IDSYSTEME, ADR_DEP.ADR_IDBASE, ADR_DEP.ADR_IDSOUSBASE , 1 , NULL, @IdBobine, NULL)) > 0
		AND (dbo.INT_GETCAPACITE (ADR_DEP.ADR_IDSYSTEME, ADR_DEP.ADR_IDBASE, ADR_DEP.ADR_IDSOUSBASE, 1, NULL, @IdLaize, @IdDiametre, @IdDiametre, NULL, NULL)) > 0
		AND ADR_DEP.ADR_IDTYPEMAGASIN = @ZONE_STOCK -- Stock
		AND ADR_DEP.ADR_MAGASIN = @MAGASIN_STOCK_DE_MASSE -- Stock de Masse
		AND ADR_DEP.ADR_IDSOUSBASE > 0 -- Adresse Fine			
		AND NOT EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME=ADR_DEP.ADR_IDSYSTEME AND CHG_IDBASE = ADR_DEP.ADR_IDBASE AND CHG_IDSOUSBASE = ADR_DEP.ADR_IDSOUSBASE AND CHG_CONTROLE=1) 
		AND SCB_LAIZE = @IdLaize
		AND SCB_DIAMETRE = @IdDiametre
		AND SCB_IDFOURNISSEUR = @IdFournisseur
		AND SCB_GRAMMAGE = @CodeGrammage
		AND DEC_DEP.ADR_IDTYPEMAGASIN = 5
		and not exists( select	1 from INT_MISSION_VIVANTE join SPC_DMD_REORGA_STOCK_GENERAL  on SDG_IDDEMANDE = MIS_DEMANDE
						where SDG_IDSYSTEME_DEPOSE = ADR_DEP.ADR_IDSYSTEME and SDG_IDBASE_DEPOSE = ADR_DEP.ADR_IDBASE and SDG_IDSOUSBASE_DEPOSE = ADR_DEP.ADR_IDSOUSBASE
						and MIS_IDETATMISSION in ( 1, 2, 3, 4 ))
	ORDER BY SCB_DATE_STOCKAGE DESC
	IF @@ROWCOUNT > 0
	begin
		SET @v_retour = @CODE_OK
	end
END

-- 2. Recherche d'une allée réservée 
--	pour l'un au moins des critères du type de la bobine
--		+ Avec de la place
--		+ Autorisée en dépose
--		+ Non Affectée en Stock Tampon 
--  => Tri par nombre de critères de réservation croissant
--	=> Puis par capacité de stockage croissante
----------------------------------------------------------
IF @v_retour <> @CODE_OK
BEGIN
		SET @ChaineTrace = 'Allée réservée'
		EXEC INT_ADDTRACESPECIFIQUE @v_transaction, 'DEBUG', @ChaineTrace
	SELECT TOP 1 @v_tac_idsystemeaffinage = DEC_DEP.ADR_IDSYSTEME, @v_tac_idbaseaffinage = DEC_DEP.ADR_IDBASE,@v_tac_idsousbaseaffinage = DEC_DEP.ADR_IDSOUSBASE,		
			@v_tac_idsystemeexecution = ADR_DEP.ADR_IDSYSTEME,@v_tac_idbaseexecution = ADR_DEP.ADR_IDBASE,@v_tac_idsousbaseexecution = ADR_DEP.ADR_IDSOUSBASE
		FROM INT_ADRESSE ADR_DEP
	LEFT OUTER JOIN SPC_ADRESSE_STOCK_GENERAL on SAG_IDSYSTEME = ADR_DEP.ADR_IDSYSTEME and SAG_IDBASE = ADR_DEP.ADR_IDBASE and SAG_IDSOUSBASE = ADR_DEP.ADR_IDSOUSBASE
	inner join INT_ADRESSE DEC_DEP on  ADR_DEP.ADR_MAGASIN = DEC_DEP.ADR_MAGASIN
									AND ADR_DEP.ADR_COTE = DEC_DEP.ADR_COTE
									AND ADR_DEP.ADR_RACK = DEC_DEP.ADR_RACK
	WHERE ADR_DEP.ADR_AUTORISATIONDEPOSE = 1
		AND ADR_DEP.ADR_VERIFICATION = 0 -- Allée Contrôle OK
		AND (ADR_DEP.ADR_IDETAT_OCCUPATION = @ALLEE_VIDE)
		AND ADR_DEP.ADR_IDTYPEMAGASIN = @ZONE_STOCK -- Stock
		AND ADR_DEP.ADR_MAGASIN = @MAGASIN_STOCK_DE_MASSE -- Stock de Masse
		AND ADR_DEP.ADR_IDSOUSBASE > 0 -- Adresse Fine
		AND DEC_DEP.ADR_IDTYPEMAGASIN = 5
		AND ((SAG_LAIZE = @IdLaize OR SAG_LAIZE IS NULL) -- Vérif des réservations
				AND (SAG_DIAMETRE = @IdDiametre OR SAG_DIAMETRE IS NULL)
				AND (SAG_IDFOURNISSEUR = @IdFournisseur OR SAG_IDFOURNISSEUR IS NULL)
				AND (SAG_GRAMMAGE = @CodeGrammage OR SAG_GRAMMAGE IS NULL)
				AND NOT (SAG_LAIZE IS NULL AND SAG_DIAMETRE IS NULL AND SAG_IDFOURNISSEUR IS NULL AND SAG_GRAMMAGE IS NULL))
		and not exists( select	1 from INT_MISSION_VIVANTE join SPC_DMD_REORGA_STOCK_GENERAL  on SDG_IDDEMANDE = MIS_DEMANDE
						where SDG_IDSYSTEME_DEPOSE = ADR_DEP.ADR_IDSYSTEME and SDG_IDBASE_DEPOSE = ADR_DEP.ADR_IDBASE and SDG_IDSOUSBASE_DEPOSE = ADR_DEP.ADR_IDSOUSBASE
						and MIS_IDETATMISSION in ( 1, 2, 3, 4 ))
	IF @@ROWCOUNT > 0
		SET @v_retour = @CODE_OK
END

-- 3. Recherche d'une allée vide
--		+ Autorisée en dépose
--		+ Non Affectée en Stock Tampon 
--	=> Tri par capacité de stockage croissante
----------------------------------------------
IF @v_retour <> @CODE_OK
BEGIN
		SET @ChaineTrace = 'Allée vide'
		EXEC INT_ADDTRACESPECIFIQUE @v_transaction, 'DEBUG', @ChaineTrace
	SELECT TOP 1 @v_tac_idsystemeaffinage = DEC_DEP.ADR_IDSYSTEME, @v_tac_idbaseaffinage = DEC_DEP.ADR_IDBASE,
			@v_tac_idsousbaseaffinage = DEC_DEP.ADR_IDSOUSBASE,
			@v_tac_idsystemeexecution = ADR_DEP.ADR_IDSYSTEME,@v_tac_idbaseexecution = ADR_DEP.ADR_IDBASE ,@v_tac_idsousbaseexecution = ADR_DEP.ADR_IDSOUSBASE
		FROM INT_ADRESSE ADR_DEP
		LEFT OUTEr JOIN SPC_ADRESSE_STOCK_GENERAL on ADR_DEP.ADR_IDSYSTEME = SAG_IDSYSTEME and ADR_DEP.ADR_IDBASE = SAG_IDBASE and ADR_DEP.ADR_IDSOUSBASE = SAG_IDSOUSBASE
		inner join INT_ADRESSE DEC_DEP on  ADR_DEP.ADR_MAGASIN = DEC_DEP.ADR_MAGASIN
									AND ADR_DEP.ADR_COTE = DEC_DEP.ADR_COTE
									AND ADR_DEP.ADR_RACK = DEC_DEP.ADR_RACK
	WHERE ADR_DEP.ADR_AUTORISATIONDEPOSE = 1
		AND ADR_DEP.ADR_VERIFICATION = 0 -- Allée Contrôle OK
		AND ADR_DEP.ADR_IDETAT_OCCUPATION = @ALLEE_VIDE
		AND ADR_DEP.ADR_IDTYPEMAGASIN = @ZONE_STOCK -- Stock
		AND ADR_DEP.ADR_MAGASIN = @MAGASIN_STOCK_DE_MASSE -- Stock de Masse
		AND ADR_DEP.ADR_IDSOUSBASE > 0 -- Adresse Fine
		AND DEC_DEP.ADR_IDTYPEMAGASIN = 5	
		AND (SAG_LAIZE IS NULL 
				AND SAG_IDFOURNISSEUR IS NULL
				AND SAG_GRAMMAGE IS NULL
				AND SAG_DIAMETRE IS NULL) -- OU Sans aucune réservation
		and not exists( select	1 from INT_MISSION_VIVANTE join SPC_DMD_REORGA_STOCK_GENERAL  on SDG_IDDEMANDE = MIS_DEMANDE
						where SDG_IDSYSTEME_DEPOSE = ADR_DEP.ADR_IDSYSTEME and SDG_IDBASE_DEPOSE = ADR_DEP.ADR_IDBASE and SDG_IDSOUSBASE_DEPOSE = ADR_DEP.ADR_IDSOUSBASE
						and MIS_IDETATMISSION in ( 1, 2, 3, 4 ))
	IF @@ROWCOUNT > 0
		SET @v_retour = @CODE_OK
END

-- 4. Recherche d'une allée	contenant le même type de bobine
--		+ Avec de la place
--		+ Autorisée en dépose
--		+ Non Affectée en Stock Tampon
--	=> Arrivé à ce stade, si je trouve une allée de ce type, elle est forcément ouverte en sortie
--	=> On prend l'allée où est stockée la bobine la + jeune
IF @v_retour <> @CODE_OK
BEGIN
		SET @ChaineTrace = 'Allée en sortie'
		EXEC INT_ADDTRACESPECIFIQUE @v_transaction, 'DEBUG', @ChaineTrace
	SELECT TOP 1 @v_tac_idsystemeaffinage = DEC_DEP.ADR_IDSYSTEME, @v_tac_idbaseaffinage = DEC_DEP.ADR_IDBASE,@v_tac_idsousbaseaffinage = DEC_DEP.ADR_IDSOUSBASE,
			@v_tac_idsystemeexecution = ADR_DEP.ADR_IDSYSTEME,@v_tac_idbaseexecution = ADR_DEP.ADR_IDBASE,@v_tac_idsousbaseexecution = ADR_DEP.ADR_IDSOUSBASE
		FROM INT_ADRESSE ADR_DEP
		LEFT OUTER JOIN SPC_ADRESSE_STOCK_GENERAL ON ADR_DEP.ADR_IDSYSTEME = SAG_IDSYSTEME
									AND ADR_DEP.ADR_IDBASE = SAG_IDBASE
									AND ADR_DEP.ADR_IDSOUSBASE = SAG_IDSOUSBASE
		INNER JOIN INT_CHARGE_VIVANTE ON CHG_IDSYSTEME = ADR_DEP.ADR_IDSYSTEME
									AND CHG_IDBASE = ADR_DEP.ADR_IDBASE
									AND CHG_IDSOUSBASE = ADR_DEP.ADR_IDSOUSBASE
		INNER JOIN SPC_CHARGE_BOBINE ON SCB_IDCHARGE = CHG_IDCHARGE
		inner join INT_ADRESSE DEC_DEP on  ADR_DEP.ADR_MAGASIN = DEC_DEP.ADR_MAGASIN
									AND ADR_DEP.ADR_COTE = DEC_DEP.ADR_COTE
									AND ADR_DEP.ADR_RACK = DEC_DEP.ADR_RACK
	WHERE ADR_DEP.ADR_AUTORISATIONDEPOSE = 1
		AND (dbo.INT_GETSTOCKABILITE (ADR_DEP.ADR_IDSYSTEME, ADR_DEP.ADR_IDBASE, ADR_DEP.ADR_IDSOUSBASE , 1 , NULL, @IdBobine, NULL)) > 0
		AND (dbo.INT_GETCAPACITE (ADR_DEP.ADR_IDSYSTEME, ADR_DEP.ADR_IDBASE, ADR_DEP.ADR_IDSOUSBASE, 1, NULL, @IdLaize, @IdDiametre, @IdDiametre, NULL, NULL)) > 0
		AND ADR_DEP.ADR_VERIFICATION = 0 -- Allée Contrôle OK
		AND ADR_DEP.ADR_IDTYPEMAGASIN = @ZONE_STOCK -- Stock
		AND ADR_DEP.ADR_MAGASIN = @MAGASIN_STOCK_DE_MASSE -- Stock de Masse
		AND ADR_DEP.ADR_IDSOUSBASE > 0 -- Adresse Fine			
		AND NOT EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME=ADR_DEP.ADR_IDSYSTEME AND CHG_IDBASE = ADR_DEP.ADR_IDBASE AND CHG_IDSOUSBASE = ADR_DEP.ADR_IDSOUSBASE AND CHG_CONTROLE=1) 
		AND SCB_LAIZE = @IdLaize
		AND SCB_DIAMETRE = @IdDiametre
		AND SCB_IDFOURNISSEUR = @IdFournisseur
		AND SCB_GRAMMAGE = @CodeGrammage
		AND DEC_DEP.ADR_IDTYPEMAGASIN = 5
		and not exists( select	1 from INT_MISSION_VIVANTE join SPC_DMD_REORGA_STOCK_GENERAL  on SDG_IDDEMANDE = MIS_DEMANDE
						where SDG_IDSYSTEME_DEPOSE = ADR_DEP.ADR_IDSYSTEME and SDG_IDBASE_DEPOSE = ADR_DEP.ADR_IDBASE and SDG_IDSOUSBASE_DEPOSE = ADR_DEP.ADR_IDSOUSBASE
						and MIS_IDETATMISSION in ( 1, 2, 3, 4 ))
	ORDER BY SCB_DATE_STOCKAGE ASC
	IF @@ROWCOUNT > 0
		SET @v_retour = @CODE_OK
END

	SET @ChaineTrace = 'Allée Trouvée:'+CONVERT(varchar,isnull(@v_tac_idbaseaffinage,0))
	EXEC INT_ADDTRACESPECIFIQUE @v_transaction, 'DEBUG', @ChaineTrace

-- Gestion des fermetures de transactions
-----------------------------------------
/*IF @v_retour <> @CODE_OK
BEGIN
	IF @v_local = 1
		ROLLBACK TRAN @v_transaction
END
ELSE IF @v_local = 1
	COMMIT TRAN @v_transaction*/
	
RETURN @v_retour

END

