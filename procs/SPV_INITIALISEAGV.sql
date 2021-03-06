SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procedure		: SPV_INITIALISEAGV
-- Paramètre d'entrée	: @v_idAgv : Identifiant de l'Agv
--			  @v_agvCharge : spécifie si l'agv est chargé ou non 
--			    - agv non chargé => @v_agvCharge = 0
--			    - agv chargé => @v_agvCharge = 1
--			  @v_idLangue : Identifiant de la langue 
--			  @v_iag_base_dest : Base de destination en cours
--			  @v_nbCharge : Nombre de charge
--			  @v_lstCharge : Chaîne de caractères listant les charges
--			  Pour chaque charge : [idcharge;adrsys;adrBase;adrSsBase;]
-- Paramètre de sortie	: Code de retour par défaut
--			    - @CODE_OK : L'initialisation s'est exécutée sans erreur
--			    - @CODE_KO_SQL : Une erreur s'est produite lors de l'initialisation
--			    - @CODE_KO_INATTENDU : L'initialisation est refusée car l'Agv est chargée
--			    et l'initialisation chargée n'est pas supportée.
--			    - @CODE_KO_INCOMPATIBLE : L'initialisation est refusée car il y a incompatibilité
--			    entre l'occupation physique et logique de l'Agv 
--			    - @CODE_KO_INTERDIT : L'initialisation est refusée car l'agv n'appartient pas à un 
--			    mode d'exploitation courant ou parce que le nombre maximum d'agv toléré dans le mode
--			    d'exploitation est atteint.
--			    - @CODE_KO_EXECUTE_FCT : L'initialisation est refusée car une erreur s'est produite
--			    - @CODE_KO_SPECIFIQUE : L'initialisation est refusée par une gestion spécifique
--			  @v_msgRefus : Message de refus d'initialisation
--			  @v_horametre : Horametre sauvegarde en BDD
-- Descriptif		: Cette procédure initialise un Agv du côté supervision
--			  Elle s'assure que l'Agv est admis dans le mode d'exploitation courant 
--			  Si il existe un ordre en cours elle interrompt l'ordre agv en cours d'exécution.
--			  S'il existe des ordres en attente dont la description indique qu'il a été envoyé,
--			  cette information est supprimée.
--			  Elle vérifie la validité des ordres suivants.
--			  Dans le cas de l'intialisation chargée, elle relance les ordres stoppés
--			  Elle vérifie la cohérence de l'occupation physique / logique de l'Agv.
--			  Elle met à jour l'état de l'Agv.
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_INITIALISEAGV]
	@v_idAgv tinyint,
	@v_agvCharge bit,
	@v_idLangue varchar(3),
	@v_iag_accostage_dest int,
	@v_iag_base_dest bigint,
	@v_msgRefus varchar(8000) out,
	@v_horametre float out,
	@v_nbCharge int,
	@v_lstCharge varchar(8000)
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
	@v_strTmp varchar(8000),
	@v_pos int,
	@v_idxCharge int,
	@v_chg_idcharge int,
	@v_chg_idsysteme bigint,
	@v_chg_idbase bigint,
	@v_chg_idsousbase bigint
	
DECLARE @v_charge table(CHG_ID int NOT NULL, CHG_ADR_KEYSYS bigint NOT NULL, CHG_ADR_KEYBASE bigint NOT NULL, CHG_ADR_KEYSSBASE bigint NOT NULL)

--déclaration des variables
declare @v_initChargee varchar(8)
declare @v_idOrdre integer
declare @v_codeInterruption tinyint
declare @v_modeExploit int
declare @v_nbAgvMax tinyint
declare @v_nbAgvEs tinyint
declare @v_idMission integer
declare @v_beforeInit varchar(128)
declare @v_init varchar(128)
declare @v_afterInit varchar(128)
declare @v_idMsgRefus integer

-- déclaration des constantes de code retour 
declare @CODE_OK tinyint
declare @CODE_KO tinyint
declare @CODE_KO_SQL tinyint
declare @CODE_KO_INATTENDU tinyint
declare @CODE_KO_INCOMPATIBLE tinyint
declare @CODE_KO_EXECUTE_FCT tinyint
declare @CODE_KO_INTERDIT tinyint
declare @CODE_KO_SPECIFIQUE tinyint

-- déclaration des constantes des états Agv
declare @ETAT_KO bit
declare @ETAT_OK bit

-- déclaration des constantes des états ordres Agv
declare @ID_ETAT_ENATTENTE tinyint
declare @ID_ETAT_ENCOURS tinyint
declare @ID_ETAT_STOP tinyint

-- déclaration des constantes des détails état ordre Agv
declare @INIT_AGV tinyint
declare @RELANCE_INTERNE tinyint

-- Déclaration des constantes de description des états ordres
DECLARE
	@ID_DSC_ENVOYE tinyint
	
-- Déclaration des constantes d'action
DECLARE
	@ACTI_CONTROLE_FERMETURE_PORTE tinyint
	
-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_AGV tinyint	

-- Définition des constantes
	SET @ETAT_KO = 0
	SET @ETAT_OK = 1
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INATTENDU = 16
	SET @CODE_KO_EXECUTE_FCT = 15
	SET @CODE_KO_INCOMPATIBLE = 14
	SET @CODE_KO_INTERDIT = 18
	SET @CODE_KO_SPECIFIQUE = 20
	SET @ID_ETAT_ENATTENTE = 1
	SET @ID_ETAT_ENCOURS = 2
	SET @ID_ETAT_STOP = 3
	SET @INIT_AGV = 5
	SET @RELANCE_INTERNE = 11
	SET @ID_DSC_ENVOYE = 13
	SET @ACTI_CONTROLE_FERMETURE_PORTE = 3
	SET @TYPE_AGV = 1

-- initialisation des autres variables
set @v_codeInterruption=@INIT_AGV

-- Initialisation de la variable de retour
	SELECT @v_error = 0
	SELECT @v_retour = @CODE_KO


-- recuperation de l'horametre
select @v_horametre=IAG_HORAMETRE from INFO_AGV where IAG_ID=@v_idAgv

--------------------------------------------------------------------------------------------
--         MISE A JOUR DE L'ETAT AGV
--------------------------------------------------------------------------------------------
	UPDATE INFO_AGV SET IAG_BASE_DEST = @v_iag_base_dest, IAG_ACCOSTAGE_DEST = @v_iag_accostage_dest,
		IAG_IDPOINTARRET = 0, IAG_POINTARRET = NULL WHERE IAG_ID = @v_idAgv
	SET @v_error = @@ERROR
	IF @v_error <> 0 
		SET @v_retour = @CODE_KO_SQL
	ELSE
	BEGIN
		SET @v_idxCharge = 0
		SET @v_strTmp = @v_lstCharge
		WHILE ((@v_idxCharge < @v_nbCharge) AND (@v_error = @CODE_OK))
		BEGIN
			SET @v_chg_idcharge = 0
			SET @v_pos = charindex(';', @v_strTmp)
			IF @v_pos <> 0
			BEGIN
				SET @v_chg_idcharge = SUBSTRING(@v_strTmp, 1, @v_pos - 1)
				SET @v_strTmp = SUBSTRING(@v_strTmp, @v_pos + 1, len(@v_strTmp) - @v_pos)
				SET @v_pos = CHARINDEX(';', @v_strTmp)
				IF @v_pos <> 0
				BEGIN
					SET @v_chg_idsysteme = SUBSTRING(@v_strTmp, 1, @v_pos - 1)
					SET @v_strTmp = SUBSTRING(@v_strTmp, @v_pos + 1, len(@v_strTmp) - @v_pos)
					SET @v_pos = CHARINDEX(';', @v_strTmp)
					IF @v_pos <> 0
					BEGIN
						SET @v_chg_idbase = SUBSTRING(@v_strTmp, 1, @v_pos - 1)
						SET @v_strTmp = SUBSTRING(@v_strTmp, @v_pos + 1, len(@v_strTmp) - @v_pos)
						SET @v_pos = CHARINDEX(';', @v_strTmp)
						IF @v_pos <> 0
						BEGIN
							SET @v_chg_idsousbase = SUBSTRING(@v_strTmp, 1, @v_pos - 1)
							INSERT INTO @v_charge VALUES (@v_chg_idcharge, @v_chg_idsysteme, @v_chg_idbase, @v_chg_idsousbase)
							SET @v_strTmp = SUBSTRING(@v_strTmp, @v_pos + 1, len(@v_strTmp) - @v_pos)
						END
					END
				END
			END
			SET @v_idxCharge = @v_idxCharge + 1
		END
		UPDATE ADRESSE SET ADR_OCCUPATION_PHYSIQUE = 0 WHERE EXISTS (SELECT 1 FROM BASE WHERE BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE AND BAS_TYPE_MAGASIN = @TYPE_AGV AND BAS_MAGASIN = @v_idAgv)
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			UPDATE ADRESSE SET ADR_OCCUPATION_PHYSIQUE = 1 WHERE EXISTS (SELECT 1 FROM @v_charge WHERE CHG_ADR_KEYSYS = ADR_SYSTEME AND CHG_ADR_KEYBASE = ADR_BASE AND CHG_ADR_KEYSSBASE = ADR_SOUSBASE)
			SET @v_error = @@ERROR
			IF @v_error <> 0
				SET @v_retour = @CODE_KO_SQL
		END
		ELSE
			SET @v_retour = @CODE_KO_SQL
	END

--------------------------------------------------------------------------------------------
--         TRAITEMENT SPECIFIQUE AVANT INITIALISATION
--------------------------------------------------------------------------------------------
	IF @v_error = 0
	BEGIN
		-- Recupération du paramètre précisant si un traitement spécifique est à réaliser avant
		select @v_beforeInit = case PAR_VAL when '' THEN NULL else PAR_VAL end from PARAMETRE where PAR_NOM = 'BEFORE_INIT'
		if @v_beforeInit is not NULL
		begin
		exec @v_beforeInit @v_idAgv, @v_agvCharge
		end
	END

--------------------------------------------------------------------------------------------
--         CONTROLE SI L'AGV EST ADMIS DANS LE MODE D'EXPLOITATION COURANT
--------------------------------------------------------------------------------------------

if @v_error = 0
begin
  -- Récupération du mode d'exploitation de l'agv et du nombre maximum d'agv admis dans le mode
  select @v_modeExploit=IAG_MODE_EXPLOIT,@v_nbAgvMax=MOD_NbAgvMax
  from MODE_EXPLOITATION,INFO_AGV
  where (IAG_Mode_Exploit=MOD_IdMode)and(IAG_ID=@v_idAgv)

  -- vérification que l'agv appartient à un mode d'exploitation
  if (@v_modeExploit is NULL)
  begin
    -- l'Agv initialisé n'est prévu dans aucun mode d'exploitation
    set @v_error = @CODE_KO_INTERDIT    
  end
  else
  begin
    -- récupération du nombre d'agv déjà actifs dans le mode
    select @v_nbAgvEs = count(*) from INFO_AGV
    	where IAG_OPERATIONNEL = 'O'
    	and IAG_MODE_EXPLOIT = @v_modeExploit and IAG_Id <> @v_idAgv

    if (@v_nbAgvEs > @v_nbAgvMax)or(@v_nbAgvEs=@v_nbAgvMax)
    begin
      -- La limite maximale d'agv dans le mode d'exploitation est atteinte
      set @v_error = @CODE_KO_INTERDIT
    end
  end
end


	--------------------------------------------------------------------------------------------
	--         CONTROLE DE LA COHERENCE LOGIQUE/PHYSIQUE 
	--------------------------------------------------------------------------------------------
	IF @v_error = 0
	BEGIN
		-- Récupération du paramètre précisant si l'initialisation chargée est acceptée ou non
		SELECT @v_initChargee = ISNULL(PAR_VAL, 'FALSE') FROM PARAMETRE
			WHERE PAR_NOM = 'INIT_CHARGEE'
		-- Vérification de la cohérence logique/physique
		IF (@v_agvCharge = 1) AND (@v_initChargee = 'FALSE')
		BEGIN
			-- L'initialisation chargée n'est pas supportée
			SELECT @v_error = @CODE_KO_INATTENDU
		END
		ELSE
		BEGIN
			IF EXISTS (SELECT 1 FROM BASE INNER JOIN ADRESSE ON ADR_SYSTEME = BAS_SYSTEME AND ADR_BASE = BAS_BASE
				LEFT OUTER JOIN CHARGE C1 ON C1.CHG_ADR_KEYSYS = ADR_SYSTEME AND C1.CHG_ADR_KEYBASE = ADR_BASE AND C1.CHG_ADR_KEYSSBASE = ADR_SOUSBASE AND C1.CHG_TODESTROY = 0
				LEFT OUTER JOIN @v_charge C2 ON C2.CHG_ADR_KEYSYS = ADR_SYSTEME AND C2.CHG_ADR_KEYBASE = ADR_BASE AND C2.CHG_ADR_KEYSSBASE = ADR_SOUSBASE
				WHERE BAS_TYPE_MAGASIN = 1 AND BAS_MAGASIN = @v_idAgv
				AND ((C2.CHG_ID <> C1.CHG_ID) OR (C2.CHG_ID IS NOT NULL AND C1.CHG_ID IS NULL)
				OR (C2.CHG_ID IS NULL AND C1.CHG_ID IS NOT NULL)))
				SET @v_error = @CODE_KO_INCOMPATIBLE
		END
	END

--------------------------------------------------------------------------------------------
--         GESTION SPECIFIQUE DE L'INITIALISATION
--------------------------------------------------------------------------------------------

if @v_error = 0
begin
  -- Recupération du paramètre précisant s'il existe une gestion spécifique
  select @v_init = case PAR_VAL when '' THEN NULL else PAR_VAL end from PARAMETRE where PAR_NOM = 'INIT'
  if @v_init is not NULL
  begin
    exec @v_error = @v_init @v_idAgv, @v_agvCharge, @v_idMsgRefus out
    if @v_error <> @CODE_OK
    begin
      if @v_error = @CODE_KO_SPECIFIQUE
        set @v_msgRefus = dbo.INT_GETLIBELLE(@v_idMsgRefus, @v_idLangue)
      else
      begin
        set @v_msgRefus = NULL
        set @v_error = @CODE_KO_SPECIFIQUE
      end
    end
  end
end
--------------------------------------------------------------------------------------------
--         RELANCE DES ORDRES STOPPES DANS LE CAS DE L'INITIALISATION CHARGEE
--------------------------------------------------------------------------------------------
if @v_error = 0
begin
  -- si il s'agit d'une intialisation chargée et que celle-ci est supportée par l'installation
  if (@v_agvCharge = 1) and (@v_initChargee = 'true')
  begin
    BEGIN TRANSACTION
	-- Désaffinage des missions stoppées
	DECLARE c_mission CURSOR LOCAL FAST_FORWARD FOR SELECT TAC_IDMISSION FROM ORDRE_AGV INNER JOIN TACHE ON TAC_IDORDRE = ORD_IDORDRE
		WHERE ORD_IDAGV = @v_idAgv AND ORD_IDETAT = @ID_ETAT_STOP
	OPEN c_mission
	FETCH NEXT FROM c_mission INTO @v_idMission
	WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
	BEGIN
		EXEC @v_error = INT_RESTARTMISSION @v_idMission
		IF @v_error <> @CODE_KO_SQL
			SET @v_error = 0 
		FETCH NEXT FROM c_mission INTO @v_idMission
	END
	CLOSE c_mission
	DEALLOCATE c_mission
	IF @v_error = 0
	BEGIN
	    -- récupération de l'ordre stoppé pour l'agv classé par ordre d'exécution
		select TOP 1 @v_idMission = TAC_IdMission, @v_idOrdre = ORD_IdOrdre from TACHE,ORDRE_AGV
		where (TAC_IdOrdre=ORD_IdOrdre)and(ORD_IdAgv=@v_idAgv)and(ORD_IdEtat=@ID_ETAT_STOP)
		order by ORD_Position
		exec @v_error = SPV_RELANCEORDRE @v_idAgv, @v_idOrdre,@v_idMission, @RELANCE_INTERNE
		if @v_error <> @CODE_KO_SQL
		begin
			set @v_error = @CODE_OK 
			COMMIT TRAN
		end
		else
		begin  
			set @v_error = @CODE_KO_EXECUTE_FCT
			ROLLBACK TRAN
		end
	END
  end 
end

IF @v_error = 0
BEGIN
	BEGIN TRAN
	EXEC @v_status = SPV_PORTE @v_action = @ACTI_CONTROLE_FERMETURE_PORTE, @v_agv = @v_idAgv
	SET @v_error = @@ERROR
	IF @v_status = @CODE_OK AND @v_error = 0
		COMMIT TRAN
	ELSE
	BEGIN
		SET @v_error = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
        ROLLBACK TRAN
	END
END

--------------------------------------------------------------------------------------------
--         TRAITEMENT SPECIFIQUE APRES INITIALISATION
--------------------------------------------------------------------------------------------

if @v_error = 0
begin
  -- Recupération du paramètre précisant si un traitement spécifique est à réaliser après
  select @v_afterInit = case PAR_VAL when '' THEN NULL else PAR_VAL end from PARAMETRE where PAR_NOM = 'AFTER_INIT'
  if @v_afterInit is not NULL
  begin
    exec @v_afterInit @v_idAgv, @v_agvCharge
  end
end

--------------------------------------------------------------------------------------------
--         MISE A JOUR DE L'ETAT AGV
--------------------------------------------------------------------------------------------
	IF @v_error = 0
		SELECT @v_retour = @CODE_OK
	ELSE
		SELECT @v_retour = @v_error
	UPDATE INFO_AGV SET IAG_BASE_DEST = @v_iag_base_dest, IAG_ACCOSTAGE_DEST = @v_iag_accostage_dest, IAG_VALID_SPV = CASE @v_error WHEN 0 THEN @ETAT_OK ELSE @ETAT_KO END,
		IAG_INITIALISATION = CASE @v_retour WHEN @CODE_OK THEN NULL WHEN @CODE_KO_EXECUTE_FCT THEN 1276
		WHEN @CODE_KO_INTERDIT THEN 1277 WHEN @CODE_KO_INATTENDU THEN 1278 WHEN @CODE_KO_INCOMPATIBLE THEN 1279
		WHEN @CODE_KO_SPECIFIQUE THEN CASE WHEN @v_idMsgRefus IS NULL THEN 1276 ELSE @v_idMsgRefus END END WHERE IAG_ID = @v_idAgv
	SET @v_error = @@ERROR
	IF @v_error <> 0 AND @v_retour = @CODE_OK
		SET @v_retour = @CODE_KO_SQL
	SELECT CHG_ID, CHG_ADR_KEYSYS, CHG_ADR_KEYBASE, CHG_ADR_KEYSSBASE, CHG_POIDS,
		CASE CHG_FACE WHEN 0 THEN CHG_LARGEUR ELSE CHG_LONGUEUR END CHG_LARGEUR,
		CASE CHG_FACE WHEN 0 THEN CHG_LONGUEUR ELSE CHG_LARGEUR END CHG_LONGUEUR,
		CHG_HAUTEUR, CHG_ORIENTATION, CHG_STABILITE
	 	FROM INFO_AGV INNER JOIN BASE ON BAS_MAGASIN = IAG_ID INNER JOIN ADRESSE ON ADR_SYSTEME = BAS_SYSTEME AND ADR_BASE = BAS_BASE
	 	INNER JOIN CHARGE ON CHG_ADR_KEYSYS = ADR_SYSTEME AND CHG_ADR_KEYBASE = ADR_BASE AND CHG_ADR_KEYSSBASE = ADR_SOUSBASE
		WHERE BAS_TYPE_MAGASIN = 1 AND IAG_ID = @v_idAgv ORDER BY CHG_POSY, CHG_POSZ
	RETURN @v_retour


