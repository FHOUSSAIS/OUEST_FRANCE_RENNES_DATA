SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON





-----------------------------------------------------------------------------------------
-- Procédure		: SPV_SETCRITEREFIXEMISSION
-- Paramètre d'entrée	: @v_idCritere : Identifiant du critère à initialiser
--			  @v_idMission : Identifiant de la mission concernée
--			  @v_valueCritere : valeur d'initialisation(facultatif)
-- Paramètre de sortie	: Code de retour par défaut
--			    @CODE_OK : la valorisation s'est exécutée correctement
--			    @CODE_KO_CRITERE_MISSION : Une erreur s'est produite
-- Descriptif		: Cette procédure valorise les critères fixes d'une mission
--			    - soit à partir de la valeur passée en paramètre
--			    - soit suite à un calcul
-----------------------------------------------------------------------------------------
-- Révisions									
-----------------------------------------------------------------------------------------
-- Date			: 21/02/2005									
-- Auteur		: S.Loiseau									
-- Libellé			: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 06/10/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Paramétrabilité du nom des procédures stockées standards
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_SETCRITEREFIXEMISSION]
	@v_idCritere integer,
	@v_idMission integer,
	@v_valueCritere varchar(8000)
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
	@v_status int

-- déclaration des variables
declare @v_codeRetour integer
declare @v_adrSys bigint
declare @v_adrBase bigint
declare @v_calculCriMis varchar(128)

-- déclaration des constantes code retour
declare @CODE_OK tinyint
declare @CODE_KO tinyint
declare @CODE_KO_CRITERE_MISSION integer

-- déclaration des constantes critere
declare @CRITERE_BASEORG_MISSION tinyint
declare @CRITERE_BASEDEST_MISSION tinyint
declare @CRITERE_ZONEBASEORG_MISSION tinyint
declare @CRITERE_ZONEBASEDEST_MISSION tinyint

--définition des constantes
set @CODE_OK = 0
set @CODE_KO = 1
set @CODE_KO_CRITERE_MISSION = 30
set @CRITERE_BASEORG_MISSION = 135
set @CRITERE_BASEDEST_MISSION = 139
set @CRITERE_ZONEBASEORG_MISSION = 134
set @CRITERE_ZONEBASEDEST_MISSION = 159

-- intialisation de la variable code de retour 
set @v_codeRetour = @CODE_KO

-- VALORISATION DES CRITERES SYSTEMES

-------------------------------------------------------------------
--              Critère première adresse mission                 --
-------------------------------------------------------------------
if (@v_idCritere = @CRITERE_BASEORG_MISSION)
begin
  select @v_valueCritere=TAC_IdAdrBase from TACHE 
  where (TAC_IdMission = @v_idMission)and (TAC_Position_Tache = 1)
end

-------------------------------------------------------------------
--              Critère dernière adresse mission
-------------------------------------------------------------------
else if (@v_idCritere = @CRITERE_BASEDEST_MISSION)
begin
  select top 1 @v_valueCritere=TAC_IdAdrBase from TACHE
  where (TAC_IdMission = @v_idMission)
  order by TAC_Position_Tache desc
end

-------------------------------------------------------------------
--              Critère zone de la première adresse mission
-------------------------------------------------------------------
else if (@v_idCritere = @CRITERE_ZONEBASEORG_MISSION)
begin
  select @v_adrSys=TAC_IDADRSYS,@v_adrBase=TAC_IDADRBASE from TACHE
  where (TAC_IdMission = @v_idMission) and (TAC_Position_Tache = 1)

  -- calcul de la zone pour de la première adresse
  select top 1 @v_valueCritere = CZO_ZONE FROM ZONE_CONTENU
  where (CZO_ADR_KEY_SYS = @v_adrSys) and (CZO_ADR_KEY_BASE = @v_adrBase)
end

-------------------------------------------------------------------
--              Critère zone de la dernière adresse mission
-------------------------------------------------------------------
else if (@v_idCritere = @CRITERE_ZONEBASEDEST_MISSION)
begin
  select top 1 @v_adrSys=TAC_IdAdrSys,@v_adrBase=TAC_IdAdrBase from TACHE
  where (TAC_IdMission = @v_idMission)
  order by TAC_Position_Tache desc

  -- calcul de la zone pour de la dernière adresse
  select top 1 @v_valueCritere = CZO_ZONE FROM ZONE_CONTENU
  where (CZO_ADR_KEY_SYS = @v_adrSys) and (CZO_ADR_KEY_BASE = @v_adrBase)
end

-- VALORISATION DES CRITERES SPECIFIQUES
else
begin
  -- Recupération du nom de la fonction spécifique
  select @v_calculCriMis = case PAR_VAL when '' THEN NULL else PAR_VAL end from PARAMETRE where PAR_NOM = 'CALCUL_CRI_MIS'
  if @v_calculCriMis is not NULL
  begin
    exec @v_status = @v_calculCriMis @v_idCritere, @v_idMission, @v_valueCritere out
    SELECT @v_error = @@ERROR
    IF NOT (@v_status = @CODE_OK AND @v_error = 0)
      SELECT @v_codeRetour = @CODE_KO_CRITERE_MISSION
    end
end


	if @v_codeRetour <> @CODE_KO_CRITERE_MISSION
	begin
		EXEC @v_status = INT_SETCRITEREMISSION @v_idCritere, @v_idMission, @v_valueCritere
		SELECT @v_error = @@ERROR
		IF @v_status = @CODE_OK AND @v_error = 0
			SELECT @v_codeRetour = @CODE_OK
		ELSE
			SELECT @v_codeRetour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
	end
	return @v_codeRetour




 







