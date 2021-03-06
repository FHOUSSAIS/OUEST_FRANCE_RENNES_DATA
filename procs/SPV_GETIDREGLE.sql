SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_GETIDREGLE
-- Paramètre d'entrée	: @v_idAgv : Identifiant de l'Agv pour lequel on recherche la règle
--			  d'attribution.
--			  @v_positionRegle : Position à partir de laquelle on recherche la règle
--			  dans le contexte.
-- Paramètre de sortie	: @v_positionRegle : Position à laquelle on a trouvé la règle dans le contexte.
--			  @v_idContexte : Identifiant du contexte sélectionné
--			  @v_idRegle : Identifiant de la règle à exécuter
--			  @v_idAction : Identifiant de l'action à exécuter
-- Descriptif		: Cette procédure récupère l'identifiant de la règle et de l'action à exécuter
--			  pour un Agv donné.
--			  Elle renvoie IdRegle =0 et idAction =0 si aucune règle ou action
--			  n'ont été trouvées. 
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_GETIDREGLE]
	@v_idAgv tinyint,
	@v_idContexte int out,
	@v_idRegle int out,
	@v_idAction int out,
	@v_positionRegle tinyint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_idActionRegle int, -- action associée à une règle
	@v_idActionCOB int, -- action associée à la combinaison
	@v_newPositionRegle tinyint,
	@v_mod_idmode int,
	@v_jeu_idjeu int

-- Déclaration des constantes d'actions et de types actions
DECLARE
	@ACTI_AVANCE_AUTOMATIQUE tinyint,
	@ACTI_ATTRIBUTION_MISSION tinyint

-- Déclaration des constantes de mode d'exploitation
DECLARE
	@MODE_TEST int
	
-- Déclaration des constantes de règle d'attribution
DECLARE
	@REGL_MISSION_DEDIEE int

-- Définition des constantes
	SET @ACTI_AVANCE_AUTOMATIQUE = 30
	SET @ACTI_ATTRIBUTION_MISSION = 36
	SET @MODE_TEST = 1
	SET @REGL_MISSION_DEDIEE = 1

-- Intialisation des paramètres de sortie
	SET @v_idContexte  = 0
	SET @v_idRegle  = 0
	SET @v_idAction = 0

	-- Récupération du mode d'exploitation et du jeu associé de l'agv
	SELECT @v_mod_idmode = MOD_IDMODE, @v_jeu_idjeu = MOD_IDJEUREGLE FROM MODE_EXPLOITATION
		WHERE MOD_IDMODE = (SELECT IAG_MODE_EXPLOIT FROM INFO_AGV WHERE IAG_ID = @v_idAgv)
	IF @v_mod_idmode <> @MODE_TEST
	BEGIN
		-- Récupération du contexte associé à la position de l'agv
		exec SPV_GETCONTEXTE @v_idAgv, @v_jeu_idjeu, @v_idContexte out
		if (@v_idContexte <> 0)
		begin
			-- un contexte a été trouvé, recherchons la règle à exécuter
			-- récupération de la règle et action courante programmées par l'utilisateur
			SELECT TOP 1 @v_idRegle = ISNULL(CDR_IDREGLE, 0), @v_idActionRegle = ISNULL(CDR_IDACTION, 0),
				@v_newPositionRegle = CDR_POSITION_REGLE, @v_idActionCOB = ISNULL(COB_ACTION, 0)
				FROM COMBINAISON LEFT OUTER JOIN COMBINAISON_DE_REGLE ON CDR_IDCOMBINAISON = COB_IDCOMBINAISON
				AND CDR_ACTIF = 1 AND CDR_POSITION_REGLE >= @v_positionRegle LEFT OUTER JOIN REGLE ON REG_IDREGLE = CDR_IDREGLE
				WHERE COB_IDCONTEXTE = @v_idContexte AND COB_IDJEU = @v_jeu_idjeu
				ORDER BY CDR_POSITION_REGLE
			if (@v_newPositionRegle is NULL)
			begin
				-- aucune règle n'a été trouvée, vérification s'il existe une action liée à la combinaison
				set @v_idRegle=0
				set @v_idAction = isNULL(@v_idActionCOB,0)
			end 
			else
			begin
				-- une règle a été trouvé
				set @v_idAction = @v_idActionRegle
				set @v_positionRegle = @v_newPositionRegle
			end 
		end
		-- aucune règle programmée n'a été trouvée
		-- vérifions si l'agv doit réaliser une avance automatique dans une zone
		-- pour cela il doit être sur une base appartenant à une zone d'attente
		-- et n'étant pas la base de sortie de la zone
		if (@v_idRegle = 0) and (@v_idAction = 0)
		begin
			if exists (select IAG_BASE_DEST from INFO_AGV, ZONE_CONTENU, ZONE
				where CZO_ADR_KEY_BASE = IAG_BASE_DEST and ZNE_ID = CZO_ZONE and ZNE_TYPE = 1
					and IAG_Id = @v_idAgv)
			begin
				set @v_idAction = @ACTI_AVANCE_AUTOMATIQUE 
 	 		end
		end
	END
	ELSE
	BEGIN
		IF @v_positionRegle = 1
		BEGIN
			SET @v_positionRegle = 1
			SET @v_idAction = @ACTI_ATTRIBUTION_MISSION
			SET @v_idRegle = @REGL_MISSION_DEDIEE
		END
		ELSE
		BEGIN
			SET @v_idAction = 0
			SET @v_idRegle = 0
		END
	END

